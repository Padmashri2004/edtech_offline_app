import 'package:logger/logger.dart';

class TextbookParser {
  static final Logger _logger = Logger();

  /// Cleans and chunks text for Member 1's AI logic
  static List<String> cleanAndChunk(String rawText, {int chunkSize = 2000}) {
    _logger.i("🛠️ Member 1: Starting text cleaning and chunking...");

    // 1. Noise Removal Logic
    String cleaned = rawText
        // Remove common PDF footers like "Page 1 of 100"
        .replaceAll(RegExp(r'Page \d+ of \d+', caseSensitive: false), '')
        // Remove standalone page numbers
        .replaceAll(RegExp(r'\n\s*\d+\s*\n'), '\n')
        // Remove multiple consecutive newlines and tabs
        .replaceAll(RegExp(r'\n+'), '\n')
        .replaceAll(RegExp(r'\t+'), ' ')
        // Remove redundant textbook headers (e.g., "NCERT Science Class 6")
        .replaceAll(RegExp(r'NCERT.*Class 6', caseSensitive: false), '')
        .trim();

    // 2. Chunking Logic (Context Window Management)
    List<String> chunks = [];
    for (var i = 0; i < cleaned.length; i += chunkSize) {
      int end = (i + chunkSize < cleaned.length) ? i + chunkSize : cleaned.length;
      chunks.add(cleaned.substring(i, end));
    }

    _logger.i("✅ Member 1: Processed ${chunks.length} chunks for AI.");
    return chunks;
  }
}