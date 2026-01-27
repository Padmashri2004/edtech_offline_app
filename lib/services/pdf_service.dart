import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:pdf_render/pdf_render.dart';
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
    try {
      if (!await file.exists()) return [];

      PDFDoc doc = await PDFDoc.fromFile(file);
      int total = doc.length;
      int scan = total < 15 ? total : 15;

      for (int i = 0; i < scan; i++) {
        String text = await doc.pageAt(i).text;
        if (text.toLowerCase().contains('content') ||
            text.toLowerCase().contains('index')) {
          chapters.addAll(_parseTocLines(text.split('\n'), total));
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
        if (k < chapters.length - 1) {
          chapters[k]['endPage'] = chapters[k + 1]['startPage'] - 1;
        } else {
          chapters[k]['endPage'] = total;
        }
      }

      return chapters;
    } catch (e) {
      _logger.e("Chapter scan error: $e");
      return [];
    }
  }

  Future<String> extractChapterText(File file, int start, int end) async {
    try {
      if (!await file.exists()) return "";

      PDFDoc doc = await PDFDoc.fromFile(file);
      StringBuffer buffer = StringBuffer();

      int s = start < 1 ? 1 : start;
      int e = end > doc.length ? doc.length : end;

      for (int i = s; i <= e; i++) {
        buffer.writeln(await doc.pageAt(i - 1).text);
      }

      return buffer.toString();
    } catch (e) {
      _logger.e("Text extraction error: $e");
      return "";
    }
  }

  // FIXED: Image extraction with 864x864 cropping for Gemma Vision
  Future<List<String>> extractChapterImages(
      File file, int start, int end) async {
    List<String> paths = [];
    try {
      final tempDir = await getTemporaryDirectory();
      final pdf = await PdfDocument.openFile(file.path);

      int s = start < 1 ? 1 : start;
      int e = end > pdf.pageCount ? pdf.pageCount : end;
      int step = ((e - s + 1) / 4).ceil().clamp(1, e - s + 1);

      for (int i = s; i <= e; i += step) {
        try {
          PdfPage page = await pdf.getPage(i);

          // FIXED: Render at higher resolution first
          PdfPageImage pageImg = await page.render(width: 1200, height: 1600);

          img.Image raw = img.Image.fromBytes(
            width: pageImg.width,
            height: pageImg.height,
            bytes: pageImg.pixels.buffer,
            order: img.ChannelOrder.rgba,
          );

          // FIXED: Crop to 864x864 square (Gemma Vision requirement)
          img.Image square = img.copyCropCircle(raw, radius: 432);
          img.Image resized = img.copyResize(square, width: 864, height: 864);

          List<int> png = img.encodePng(resized);
          String name = "img_${_uuid.v4()}.png";
          File f = File('${tempDir.path}/$name');
          await f.writeAsBytes(png);

          paths.add(f.path);
          pageImg.dispose();
        } catch (e) {
          _logger.w("Failed to extract image from page $i: $e");
          continue;
        }
      }

      await pdf.dispose();
    } catch (e) {
      _logger.e("Image extraction error: $e");
    }

    return paths;
  }

  Future<List<String>> scanChapterSubtopics(File f, int s, int e) async {
    return ["Introduction", "Main Concept", "Examples", "Summary"];
  }

  List<Map<String, dynamic>> _parseTocLines(List<String> lines, int total) {
    List<Map<String, dynamic>> found = [];

    final re = RegExp(r"^(\d+|Chapter \d+)[.\s]+([\w\s\-\,\']+?)[.\s]+(\d+)$",
        caseSensitive: false);

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
