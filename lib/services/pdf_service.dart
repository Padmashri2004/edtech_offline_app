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

  /// ✅ ENHANCED: Robust TOC detection with multiple patterns
  Future<List<Map<String, dynamic>>> getChapters(File file) async {
    List<Map<String, dynamic>> chapters = [];
    sf_pdf.PdfDocument? document;

    try {
      if (!await file.exists()) return [];
      document = sf_pdf.PdfDocument(inputBytes: await file.readAsBytes());
      int total = document.pages.count;
      sf_pdf.PdfTextExtractor extractor = sf_pdf.PdfTextExtractor(document);

      // ✅ STEP 1: Find TOC page (scan first 20 pages)
      int tocPageIndex = -1;
      String tocContent = '';

      for (int i = 0; i < (total < 20 ? total : 20); i++) {
        String text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        String lowerText = text.toLowerCase();

        // Look for TOC indicators
        if (lowerText.contains('contents') ||
            lowerText.contains('table of contents') ||
            lowerText.contains('index')) {
          // Check if this page has chapter entries
          if (_hasChapterEntries(text)) {
            tocPageIndex = i;
            tocContent = text;
            _logger.i('✅ TOC found on page ${i + 1}');
            break;
          }
        }
      }

      // ✅ STEP 2: Parse TOC content
      if (tocPageIndex >= 0) {
        chapters = _parseEnhancedTOC(tocContent, total);
      }

      // ✅ STEP 3: Fallback - scan entire document for chapter headings
      if (chapters.isEmpty) {
        _logger.w('⚠ No TOC found, using fallback chapter detection');
        chapters = _fallbackChapterDetection(document, extractor, total);
      }

      // ✅ STEP 4: Fix endPage assignment
      for (int k = 0; k < chapters.length; k++) {
        chapters[k]['endPage'] = (k < chapters.length - 1)
            ? chapters[k + 1]['startPage'] - 1
            : total;
      }

      // ✅ STEP 5: Filter out invalid entries
      chapters = chapters.where((ch) {
        int start = ch['startPage'] as int;
        int end = ch['endPage'] as int;
        String title = ch['title'] as String;

        // Remove footer/foreword entries
        String lowerTitle = title.toLowerCase();
        if (lowerTitle.contains('foreword') ||
            lowerTitle.contains('about') ||
            lowerTitle.contains('preface') ||
            lowerTitle.contains('introduction to') ||
            lowerTitle.contains('how to use') ||
            lowerTitle.contains('rationalisation') ||
            title.length < 3) {
          return false;
        }

        // Ensure valid page range
        return start > 0 && start <= total && end >= start && end <= total;
      }).toList();

      _logger.i('✅ Found ${chapters.length} valid chapters');
      return chapters;
    } catch (e) {
      _logger.e("❌ Chapter scan error: $e");
      return [];
    } finally {
      document?.dispose();
    }
  }

  /// ✅ Check if text contains chapter entries
  bool _hasChapterEntries(String text) {
    final patterns = [
      RegExp(r'chapter\s+\d+', caseSensitive: false),
      RegExp(r'unit\s+\d+', caseSensitive: false),
      RegExp(r'lesson\s+\d+', caseSensitive: false),
      RegExp(r'^\s*\d+\.\s+\w+', multiLine: true), // "1. Title"
    ];

    for (var pattern in patterns) {
      if (pattern.hasMatch(text)) return true;
    }
    return false;
  }

  /// ✅ ENHANCED: Parse TOC with multiple format support
  List<Map<String, dynamic>> _parseEnhancedTOC(
      String tocContent, int totalPages) {
    List<Map<String, dynamic>> chapters = [];
    List<String> lines = tocContent.split('\n');

    // ✅ Pattern 1: Multi-line format (Chapter N \n Title \n Page)
    for (int i = 0; i < lines.length - 2; i++) {
      String line1 = lines[i].trim();
      String line2 = lines[i + 1].trim();
      String line3 = lines[i + 2].trim();

      // Match "Chapter 1", "Unit 1", "Lesson 1", or just "1."
      final numberPatterns = [
        RegExp(r'^(?:chapter|unit|lesson)\s+(\d+)\.?$', caseSensitive: false),
        RegExp(r'^(\d+)\.?$'),
      ];

      for (var pattern in numberPatterns) {
        var match = pattern.firstMatch(line1);
        if (match != null) {
          String num = match.group(1)!;

          // Line 2 should be title (not empty, not just a number, not a page reference)
          if (line2.isNotEmpty &&
              !RegExp(r'^\d+$').hasMatch(line2) &&
              line2.length > 2 &&
              !line2.toLowerCase().contains('page')) {
            // Line 3 should be page number
            int? pageNum = int.tryParse(line3.replaceAll(RegExp(r'[^\d]'), ''));
            if (pageNum != null && pageNum > 0 && pageNum <= totalPages) {
              chapters.add({
                'chapterNumber': num,
                'title': line2,
                'startPage': pageNum,
                'endPage': totalPages,
                'topics': <String>[]
              });
              break;
            }
          }
        }
      }
    }

    // ✅ Pattern 2: Single-line format (1. Title ... 25)
    if (chapters.isEmpty) {
      for (String line in lines) {
        String t = line.trim();
        if (t.isEmpty || t.length > 150) continue;

        // Try: "Chapter 1: Title 25" or "1. Title 25"
        final singleLinePatterns = [
          RegExp(r'^(?:chapter|unit|lesson)\s+(\d+)[\.:]\s+(.+?)\s+(\d+)$',
              caseSensitive: false),
          RegExp(r'^(\d+)[\.:]\s+(.+?)\s+(\d+)$'),
          RegExp(r'^(\d+)\.\s+(.+?)\s+\.+\s*(\d+)$'), // "1. Title ... 25"
        ];

        for (var pattern in singleLinePatterns) {
          final m = pattern.firstMatch(t);
          if (m != null) {
            try {
              String num = m.group(1)!;
              String title = m.group(2)!.trim();
              int pageNum = int.parse(m.group(3)!);

              if (pageNum > 0 && pageNum <= totalPages && title.length > 2) {
                chapters.add({
                  'chapterNumber': num,
                  'title': title,
                  'startPage': pageNum,
                  'endPage': totalPages,
                  'topics': <String>[]
                });
                break;
              }
            } catch (_) {}
          }
        }
      }
    }

    return chapters;
  }

  /// ✅ Fallback: Scan document for chapter headings
  List<Map<String, dynamic>> _fallbackChapterDetection(
      sf_pdf.PdfDocument document,
      sf_pdf.PdfTextExtractor extractor,
      int totalPages) {
    List<Map<String, dynamic>> chapters = [];

    for (int i = 0; i < totalPages; i++) {
      String text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      List<String> lines = text.split('\n');

      for (String line in lines) {
        String trimmed = line.trim();

        // Look for chapter headings at start of line
        final patterns = [
          RegExp(r'^(?:chapter|unit|lesson)\s+(\d+)[\.:]\s*(.+?)$',
              caseSensitive: false),
          RegExp(r'^(\d+)[\.:]\s+(.{5,})$'), // At least 5 chars for title
        ];

        for (var pattern in patterns) {
          var match = pattern.firstMatch(trimmed);
          if (match != null) {
            String num = match.group(1)!;
            String title =
                match.groupCount >= 2 ? match.group(2)!.trim() : 'Chapter $num';

            // Avoid duplicates
            bool isDuplicate = chapters.any(
                (ch) => ch['chapterNumber'] == num || ch['title'] == title);

            if (!isDuplicate && title.length > 2) {
              chapters.add({
                'chapterNumber': num,
                'title': title,
                'startPage': i + 1,
                'endPage': totalPages,
                'topics': <String>[]
              });
              break;
            }
          }
        }
      }
    }

    return chapters;
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
}
