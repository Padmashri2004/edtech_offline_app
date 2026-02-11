import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

class ImageExtractionService {
  final Logger _logger = Logger();

  // Extract images from PDF chapter with their captions
  Future<List<Map<String, dynamic>>> extractImagesWithCaptions(
    File pdfFile,
    int startPage,
    int endPage,
  ) async {
    final List<Map<String, dynamic>> imagesWithCaptions = [];

    try {
      final document = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      final textExtractor = PdfTextExtractor(document);

      for (int pageIndex = startPage - 1;
          pageIndex < endPage && pageIndex < document.pages.count;
          pageIndex++) {
        final page = document.pages[pageIndex];

        // Extract text from page to find captions
        final pageText = textExtractor.extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        );

        // Find figure captions
        final captions = _extractFigureCaptions(pageText);

        // ⚠️ Syncfusion Community does NOT support direct image extraction
        final images = _extractImagesFromPage(page, pageIndex + 1);

        // Match images with captions
        if (images.isNotEmpty && captions.isNotEmpty) {
          for (int i = 0; i < images.length && i < captions.length; i++) {
            final imageData = images[i];
            final caption = captions[i];

            // Save image to file
            final savedPath = await _saveImageToFile(
              imageData['bytes'] as Uint8List,
              pageIndex + 1,
              i,
            );

            if (savedPath != null) {
              imagesWithCaptions.add({
                'imagePath': savedPath,
                'caption': caption,
                'pageNumber': pageIndex + 1,
                'figureNumber': i + 1,
              });
            }
          }
        }
      }

      document.dispose();
    } catch (e) {
      _logger.e('Error extracting images: $e');
    }

    return imagesWithCaptions;
  }

  // Extract figure captions from text
  List<String> _extractFigureCaptions(String text) {
    final List<String> captions = [];
    final lines = text.split('\n');

    final patterns = [
      RegExp(r'Figure\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Fig\.?\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Diagram\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Image\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line.trim());
        if (match != null) {
          String caption = line.trim();
          if (caption.length > 100) {
            caption = '${caption.substring(0, 97)}...';
          }
          captions.add(caption);
          break;
        }
      }
    }

    return captions;
  }

  // ❌ Community edition does not support direct image extraction
  List<Map<String, dynamic>> _extractImagesFromPage(
      PdfPage page, int pageNumber) {
    final List<Map<String, dynamic>> images = [];

    try {
      _logger.w(
          'Image extraction from PDF requires Syncfusion Professional edition.');
    } catch (e) {
      _logger.e('Error extracting images from page $pageNumber: $e');
    }

    return images;
  }

  // Save image bytes to file
  Future<String?> _saveImageToFile(
      Uint8List imageBytes, int pageNumber, int imageIndex) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/extracted_images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'fig_p${pageNumber}_i${imageIndex}_$timestamp.png';
      final filePath = '${imagesDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return filePath;
    } catch (e) {
      _logger.e('Error saving image: $e');
      return null;
    }
  }

  // Match image to question based on keywords
  String? findRelevantImage(
      String questionText, List<Map<String, dynamic>> availableImages) {
    if (availableImages.isEmpty) return null;

    final questionLower = questionText.toLowerCase();

    for (final imageData in availableImages) {
      final caption = (imageData['caption'] as String).toLowerCase();

      if (_hasCommonKeywords(questionLower, caption)) {
        return imageData['imagePath'] as String;
      }
    }

    return null;
  }

  bool _hasCommonKeywords(String text1, String text2) {
    final stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'what',
      'which',
      'how',
      'why',
      'when',
      'where',
    };

    final words1 = text1
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3 && !stopWords.contains(w))
        .toSet();

    final words2 = text2
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3 && !stopWords.contains(w))
        .toSet();

    final commonWords = words1.intersection(words2);
    return commonWords.isNotEmpty;
  }
}
