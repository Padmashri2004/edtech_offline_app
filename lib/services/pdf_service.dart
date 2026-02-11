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

  /// Allow teacher to pick a textbook PDF file
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

  /// Scan PDF for chapters using TOC or fallback heading detection
  Future<List<Map<String, dynamic>>> getChapters(File file) async {
    List<Map<String, dynamic>> chapters = [];
    sf_pdf.PdfDocument? document;

    try {
      if (!await file.exists()) return [];

      document = sf_pdf.PdfDocument(inputBytes: await file.readAsBytes());
      int total = document.pages.count;
      int scan = total < 15 ? total : 15;

      sf_pdf.PdfTextExtractor extractor = sf_pdf.PdfTextExtractor(document);

      // First scan: look for TOC in first 10–15 pages
      for (int i = 0; i < scan; i++) {
        String text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        if (text.toLowerCase().contains('content') ||
            text.toLowerCase().contains('chapter')) {
          var found = _parseTocLines(text.split('\n'), total);
          chapters.addAll(found);
        }
      }

      // Fallback: full scan if TOC not found
      if (chapters.isEmpty) {
        for (int i = 0; i < total; i++) {
          String text =
              extractor.extractText(startPageIndex: i, endPageIndex: i);
          for (var line in text.split('\n')) {
            if (line.toLowerCase().startsWith("chapter")) {
              chapters.add({
                'chapterNumber': line.split(' ')[1],
                'title':
                    line.replaceFirst(RegExp(r'Chapter\s+\d+:'), '').trim(),
                'startPage': i + 1,
                'endPage': total,
                'topics': <String>[]
              });
            }
          }
        }
      }

      // Fix endPage assignment
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

  /// Extract text for selected chapter range
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

  /// Extract representative images from chapter pages
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

  /// Parse TOC lines into chapter metadata - FIXED for multi-line format
  List<Map<String, dynamic>> _parseTocLines(List<String> lines, int total) {
    List<Map<String, dynamic>> found = [];

    // Try multi-line TOC format first (Chapter 1 \n Title \n Page)
    for (int i = 0; i < lines.length - 2; i++) {
      String line1 = lines[i].trim();
      String line2 = lines[i + 1].trim();
      String line3 = lines[i + 2].trim();

      // Pattern: "Chapter N" on line 1
      RegExp chapterNumPattern =
          RegExp(r'^Chapter\s+(\d+)$', caseSensitive: false);
      var match = chapterNumPattern.firstMatch(line1);

      if (match != null) {
        String chapterNum = match.group(1)!;

        // Line 2 should be the title (not empty, not a number)
        if (line2.isNotEmpty && !RegExp(r'^\d+$').hasMatch(line2)) {
          // Line 3 should be the page number
          int? pageNum = int.tryParse(line3.trim());

          if (pageNum != null && pageNum > 0 && pageNum <= total) {
            found.add({
              'chapterNumber': chapterNum,
              'title': line2,
              'startPage': pageNum,
              'endPage': total,
              'topics': <String>[]
            });
          }
        }
      }
    }

    // If multi-line didn't work, try single-line format
    if (found.isEmpty) {
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
    }

    return found;
  }
}
