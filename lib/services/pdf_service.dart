import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;

class PdfService {
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  Future<File?> pickTextbook() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      _logger.e("Error picking file: $e");
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getChapters(File file) async {
    List<Map<String, dynamic>> chapters = [];
    sf_pdf.PdfDocument? document;
    try {
      if (!await file.exists()) return [];
      document = sf_pdf.PdfDocument(inputBytes: await file.readAsBytes());
      int total = document.pages.count;
      int scan = total < 15 ? total : 15;
      sf_pdf.PdfTextExtractor extractor = sf_pdf.PdfTextExtractor(document);

      for (int i = 0; i < scan; i++) {
        String text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        if (text.toLowerCase().contains('content') ||
            text.toLowerCase().contains('chapter')) {
          var found = _parseTocLines(text.split('\n'), total);
          chapters.addAll(found);
        }
      }

      if (chapters.isEmpty) {
        return [
          {
            'chapterNumber': "1",
            'title': "Full Textbook",
            'startPage': 1,
            'endPage': total,
            'topics': <String>[]
          }
        ];
      }

      for (int k = 0; k < chapters.length; k++) {
        chapters[k]['endPage'] = (k < chapters.length - 1)
            ? chapters[k + 1]['startPage'] - 1
            : total;
      }
      return chapters;
    } catch (e) {
      _logger.e("Chapter scan error: $e");
      return [];
    } finally {
      document?.dispose();
    }
  }

  Future<String> extractChapterText(File file, int start, int end) async {
    sf_pdf.PdfDocument? document;
    try {
      if (!await file.exists()) return "";
      document = sf_pdf.PdfDocument(inputBytes: await file.readAsBytes());
      StringBuffer buffer = StringBuffer();
      int pageCount = document.pages.count;
      int s = start < 1 ? 1 : start;
      int e = end > pageCount ? pageCount : end;
      sf_pdf.PdfTextExtractor extractor = sf_pdf.PdfTextExtractor(document);

      for (int i = s - 1; i < e; i++) {
        String pageText =
            extractor.extractText(startPageIndex: i, endPageIndex: i);
        buffer.writeln(pageText);
      }
      return buffer.toString();
    } catch (e) {
      _logger.e("Text extraction error: $e");
      return "";
    } finally {
      document?.dispose();
    }
  }

  Future<List<String>> extractChapterImages(
      File file, int start, int end) async {
    List<String> paths = [];
    try {
      final tempDir = await getTemporaryDirectory();
      final pdfBytes = await file.readAsBytes();
      int s = start < 1 ? 1 : start;
      List<int> pagesToRender = [];
      int count = end - s + 1;
      int step = (count / 5).ceil().clamp(1, count).toInt();
      for (int i = s - 1; i < end; i += step) {
        pagesToRender.add(i);
      }

      await for (var page
          in Printing.raster(pdfBytes, pages: pagesToRender, dpi: 72)) {
        try {
          final pngBytes = await page.toPng();
          img.Image? raw = img.decodePng(pngBytes);
          if (raw == null) continue;
          int size = raw.width < raw.height ? raw.width : raw.height;
          img.Image square = img.copyCrop(raw,
              x: (raw.width - size) ~/ 2,
              y: (raw.height - size) ~/ 2,
              width: size,
              height: size);
          img.Image resized = img.copyResize(square, width: 864, height: 864);
          List<int> processedPng = img.encodePng(resized);
          String name = "img_${_uuid.v4()}.png";
          File f = File('${tempDir.path}/$name');
          await f.writeAsBytes(processedPng);
          paths.add(f.path);
        } catch (e) {
          _logger.w("Failed to rasterize page: $e");
        }
      }
    } catch (e) {
      _logger.e("Image extraction error: $e");
    }
    return paths;
  }

  Future<List<String>> scanChapterSubtopics(File f, int s, int e) async {
    try {
      final text = await extractChapterText(f, s, e);
      final lines = text.split('\n');
      final subtopics = <String>[];
      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.length < 60 &&
            (RegExp(r'^\d+\.').hasMatch(trimmed) ||
                trimmed.endsWith(':') ||
                trimmed.split(' ').length <= 6)) {
          subtopics.add(trimmed);
        }
      }
      return subtopics.isEmpty
          ? ["Introduction", "Main Concept", "Examples", "Summary"]
          : subtopics;
    } catch (e) {
      _logger.w("Subtopic scan failed: $e");
      return ["Introduction", "Main Concept", "Examples", "Summary"];
    }
  }

  List<Map<String, dynamic>> _parseTocLines(List<String> lines, int total) {
    List<Map<String, dynamic>> found = [];
    final re =
        RegExp(r"^Chapter\s+(\d+):\s+(.+)\s+(\d+)$", caseSensitive: false);

    for (String line in lines) {
      String t = line.trim();
      if (t.isEmpty || t.length > 100) continue;
      final m = re.firstMatch(t);
      if (m != null) {
        try {
          int p = int.parse(m.group(3)!);
          if (p > 0 && p <= total) {
            found.add({
              'chapterNumber': m.group(1)!,
              'title': m.group(2)!.trim(),
              'startPage': p,
              'endPage': total,
              'topics': <String>[]
            });
          }
        } catch (_) {}
      }
    }
    return found;
  }
}
