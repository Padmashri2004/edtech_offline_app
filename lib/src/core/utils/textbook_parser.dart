import 'package:logger/logger.dart';

class TextbookParser {
  static final Logger _logger = Logger();

  /// Optimized cleaning and chunking to prevent App Crashes & AI Hallucinations.
  ///
  /// IMPROVEMENTS:
  /// 1. Reduced Chunk Size: 1500 chars (Safe zone for Nano model memory).
  /// 2. Smart Splitting: Cuts at periods (.), newlines (\n), or spaces.
  /// 3. Garbage Collection: Aggressive cleaning of whitespace to save tokens.
  static List<String> cleanAndChunk(String rawText, {int chunkSize = 1500}) {
    _logger.i(" 🛠️  Member 1: Starting optimized text chunking...");

    if (rawText.isEmpty) {
      _logger.w(" ⚠️  Member 1: Input text was empty.");
      return [];
    }

    // 1. Aggressive Noise Removal
    // This reduces the token count before we even start chunking.
    String cleaned = rawText
        // Remove "Page X of Y" footers common in PDFs
        .replaceAll(RegExp(r'Page \d+ of \d+', caseSensitive: false), '')
        // Remove standalone page numbers (e.g., " 12 ")
        .replaceAll(RegExp(r'\n\s*\d+\s*\n'), '\n')
        // Normalize line endings
        .replaceAll(RegExp(r'\r\n'), '\n')
        // Collapse multiple newlines to max 2 (preserves paragraph breaks, removes huge gaps)
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // Collapse tabs and multiple spaces
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        // Remove generic headers if specific to your dataset
        .replaceAll(RegExp(r'NCERT.*Class \d+', caseSensitive: false), '')
        .trim();

    List<String> chunks = [];
    int start = 0;
    int textLength = cleaned.length;

    // 2. Smart Chunking Loop
    while (start < textLength) {
      // If the remaining text fits in one chunk, take it all and finish
      if (textLength - start <= chunkSize) {
        chunks.add(cleaned.substring(start));
        break;
      }

      // Define the hard limit for this chunk
      int end = start + chunkSize;

      // SEARCH BACKWARDS Logic:
      // We look for a safe split point (period, newline) within the last 15% of the chunk.
      // This ensures we don't cut a sentence in half.
      int splitIndex = -1;
      int searchZone = (chunkSize * 0.15).toInt(); // Look back ~225 chars

      // Priority 1: Split at a paragraph break (\n)
      splitIndex = cleaned.lastIndexOf('\n', end);

      // Priority 2: Split at a sentence ending (. ! ?) if paragraph break is too far back
      if (splitIndex == -1 || splitIndex < (end - searchZone)) {
        int dot = cleaned.lastIndexOf('.', end);
        int excl = cleaned.lastIndexOf('!', end);
        int ques = cleaned.lastIndexOf('?', end);

        // Find the latest occurrence of any punctuation
        splitIndex =
            [dot, excl, ques].reduce((curr, next) => curr > next ? curr : next);
      }

      // Priority 3: Split at a space (last resort to avoid cutting a word in half)
      if (splitIndex == -1 || splitIndex < (end - searchZone)) {
        splitIndex = cleaned.lastIndexOf(' ', end);
      }

      // Fallback: If absolutely no safe split found (e.g., a massive URL or code block),
      // we are forced to hard chop at the limit.
      if (splitIndex == -1 || splitIndex <= start) {
        splitIndex = end;
      } else {
        // Include the punctuation mark in the current chunk (splitIndex is exclusive in substring)
        splitIndex += 1;
      }

      // Add the valid chunk
      chunks.add(cleaned.substring(start, splitIndex).trim());

      // Move the pointer for the next iteration
      start = splitIndex;
    }

    _logger.i(
        " ✅  Member 1: Generated ${chunks.length} safe chunks from $textLength chars.");
    return chunks;
  }
}
