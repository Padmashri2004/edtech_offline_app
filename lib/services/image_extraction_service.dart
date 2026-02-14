import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

class ImageExtractionService {
  final Logger _logger = Logger();

  // ✅ Extract images from PDF chapter with FLEXIBLE caption detection
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

        // ✅ Find ALL potential academic captions (flexible matching)
        final captions = _extractFlexibleCaptions(pageText);

        // ⚠️ Syncfusion Community does NOT support direct image extraction
        final images = _extractImagesFromPage(page, pageIndex + 1);

        // ✅ Match images with captions (or use placeholder if academic context found)
        if (images.isNotEmpty) {
          for (int i = 0; i < images.length; i++) {
            final imageData = images[i];

            // Get caption if available, otherwise generate one
            String caption;
            if (i < captions.length) {
              caption = captions[i];
            } else {
              // ✅ Generate placeholder for academic images without standard captions
              caption = _generateAcademicCaption(pageText, i);
            }

            // Only save if caption indicates academic content
            if (caption.isNotEmpty) {
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

                _logger
                    .i('✅ Extracted image: $caption (Page ${pageIndex + 1})');
              }
            }
          }
        }
      }

      document.dispose();

      _logger
          .i('✅ Total academic images extracted: ${imagesWithCaptions.length}');
    } catch (e) {
      _logger.e('❌ Error extracting images: $e');
    }

    return imagesWithCaptions;
  }

  // ✅ ENHANCED: Flexible caption extraction (handles non-standard formats)
  List<String> _extractFlexibleCaptions(String text) {
    final List<String> captions = [];
    final lines = text.split('\n');

    // ✅ Pattern 1: Standard academic labels
    final standardPatterns = [
      RegExp(r'Figure\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Fig\.?\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Diagram\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Image\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Table\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Chart\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Graph\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'Illustration\s+\d+\.?\d*\s*[:\-]?\s*(.+)', caseSensitive: false),
    ];

    // ✅ Pattern 2: Descriptive captions (without "Figure" prefix)
    final descriptivePatterns = [
      RegExp(r'(.+?\s+structure\s+.+)', caseSensitive: false),
      RegExp(r'(.+?\s+diagram\s+.+)', caseSensitive: false),
      RegExp(r'(.+?\s+process\s+.+)', caseSensitive: false),
      RegExp(r'(.+?\s+cycle\s+.+)', caseSensitive: false),
      RegExp(r'(.+?\s+system\s+.+)', caseSensitive: false),
      RegExp(r'(.+?\s+model\s+.+)', caseSensitive: false),
      RegExp(r'(.+?\s+circuit\s+.+)', caseSensitive: false),
      RegExp(r'(.+?\s+arrangement\s+.+)', caseSensitive: false),
    ];

    Set<String> foundCaptions = {}; // Prevent duplicates

    // First pass: Standard patterns
    for (final line in lines) {
      for (final pattern in standardPatterns) {
        final match = pattern.firstMatch(line.trim());
        if (match != null) {
          String caption = line.trim();
          if (_isValidCaption(caption) && !foundCaptions.contains(caption)) {
            if (caption.length > 100) {
              caption = '${caption.substring(0, 97)}...';
            }
            captions.add(caption);
            foundCaptions.add(caption);
            break;
          }
        }
      }
    }

    // ✅ Second pass: Descriptive patterns (for diagrams without "Figure" label)
    if (captions.isEmpty) {
      for (final line in lines) {
        String trimmed = line.trim();

        // Skip very short lines or page numbers
        if (trimmed.length < 15 || RegExp(r'^\d+$').hasMatch(trimmed)) {
          continue;
        }

        for (final pattern in descriptivePatterns) {
          final match = pattern.firstMatch(trimmed);
          if (match != null) {
            String caption = match.group(1)!.trim();

            if (_isValidCaption(caption) && !foundCaptions.contains(caption)) {
              if (caption.length > 100) {
                caption = '${caption.substring(0, 97)}...';
              }
              captions.add(caption);
              foundCaptions.add(caption);
              break;
            }
          }
        }
      }
    }

    return captions;
  }

  // ✅ Generate academic caption from context
  String _generateAcademicCaption(String pageText, int imageIndex) {
    // Look for academic keywords near the image position
    final academicKeywords = [
      'structure',
      'diagram',
      'process',
      'cycle',
      'system',
      'model',
      'circuit',
      'arrangement',
      'flow',
      'mechanism',
      'anatomy',
      'composition',
      'schematic',
      'representation',
      'cross-section',
      'longitudinal',
      'transverse'
    ];

    String lowerText = pageText.toLowerCase();

    for (var keyword in academicKeywords) {
      if (lowerText.contains(keyword)) {
        // Extract sentence containing the keyword
        int index = lowerText.indexOf(keyword);
        int start = lowerText.lastIndexOf('.', index);
        int end = lowerText.indexOf('.', index);

        if (start != -1 && end != -1 && end > start) {
          String sentence = pageText.substring(start + 1, end + 1).trim();

          // Validate and clean
          if (sentence.length > 15 && sentence.length < 150) {
            return 'Academic diagram: ${sentence.substring(0, sentence.length > 80 ? 80 : sentence.length)}...';
          }
        }

        // Fallback: Use keyword
        return 'Diagram ${imageIndex + 1}: ${keyword.substring(0, 1).toUpperCase()}${keyword.substring(1)} illustration';
      }
    }

    // ✅ Check if page has technical/scientific content
    if (_hasAcademicContext(pageText)) {
      return 'Academic diagram ${imageIndex + 1}';
    }

    return ''; // Not academic - skip this image
  }

  // ✅ Check if caption is valid (not decorative)
  bool _isValidCaption(String caption) {
    String lower = caption.toLowerCase();

    // ❌ Reject decorative/non-academic
    final rejectPatterns = [
      'logo',
      'banner',
      'header',
      'footer',
      'advertisement',
      'sponsored',
      'copyright',
      'watermark',
      'credit',
      'source:'
    ];

    for (var reject in rejectPatterns) {
      if (lower.contains(reject)) return false;
    }

    // ❌ Reject very short or very long
    if (caption.length < 10 || caption.length > 200) return false;

    // ✅ Accept if has academic indicators
    final acceptIndicators = [
      'structure',
      'process',
      'cycle',
      'system',
      'diagram',
      'model',
      'experiment',
      'observation',
      'figure',
      'table',
      'chart',
      'graph',
      'cell',
      'tissue',
      'organ',
      'molecule',
      'circuit',
      'apparatus',
      'setup'
    ];

    for (var indicator in acceptIndicators) {
      if (lower.contains(indicator)) return true;
    }

    return false;
  }

  // ✅ Check if page has academic context
  bool _hasAcademicContext(String text) {
    String lower = text.toLowerCase();

    final academicIndicators = [
      'chapter',
      'section',
      'exercise',
      'activity',
      'observe',
      'experiment',
      'analyze',
      'calculate',
      'describe',
      'explain',
      'identify',
      'compare',
      'photosynthesis',
      'respiration',
      'digestion',
      'atom',
      'molecule',
      'reaction',
      'equation',
      'triangle',
      'rectangle',
      'theorem',
      'proof'
    ];

    int count = 0;
    for (var indicator in academicIndicators) {
      if (lower.contains(indicator)) count++;
      if (count >= 2) return true; // At least 2 academic terms
    }

    return false;
  }

  // ❌ Community edition placeholder
  List<Map<String, dynamic>> _extractImagesFromPage(
      PdfPage page, int pageNumber) {
    final List<Map<String, dynamic>> images = [];
    try {
      _logger
          .w('⚠️ Image extraction requires Syncfusion Professional edition.');
    } catch (e) {
      _logger.e('❌ Error extracting images from page $pageNumber: $e');
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
      _logger.e('❌ Error saving image: $e');
      return null;
    }
  }

  // ✅ Match image to question based on keywords
  String? findRelevantImage(
      String questionText, List<Map<String, dynamic>> availableImages) {
    if (availableImages.isEmpty) return null;

    final questionLower = questionText.toLowerCase();

    // ✅ First pass: Exact caption keyword match
    for (final imageData in availableImages) {
      final caption = (imageData['caption'] as String).toLowerCase();
      if (_hasCommonKeywords(questionLower, caption)) {
        _logger.i('✅ Matched image: ${imageData["caption"]}');
        return imageData['imagePath'] as String;
      }
    }

    // ✅ Second pass: Question type matching
    final typeMatches = {
      'diagram': 'diagram',
      'structure': 'structure',
      'process': 'process',
      'cycle': 'cycle',
      'system': 'system',
      'circuit': 'circuit',
      'model': 'model',
      'flow': 'flow',
    };

    for (final entry in typeMatches.entries) {
      if (questionLower.contains(entry.key)) {
        for (final imageData in availableImages) {
          final caption = (imageData['caption'] as String).toLowerCase();
          if (caption.contains(entry.value)) {
            return imageData['imagePath'] as String;
          }
        }
      }
    }

    return null;
  }

  // ✅ Improved keyword matching
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
      'this',
      'that',
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
