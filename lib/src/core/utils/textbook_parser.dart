import 'package:logger/logger.dart';

class TextbookParser {
  static final Logger _logger = Logger();

  // FIXED: Reduced for Gemma 3-270M
  static const int safeChunkSizeForNano = 1200; // Reduced from 1500
  static const double searchZonePercentage = 0.15;

  static List<String> cleanAndChunk(
    String rawText, {
    int chunkSize = safeChunkSizeForNano,
  }) {
    _logger.i("🛠️ Starting optimized text chunking...");

    if (rawText.isEmpty) {
      _logger.w("⚠️ Input text was empty");
      return [];
    }

    String cleaned = _performCleaning(rawText);
    List<String> chunks = _performChunking(cleaned, chunkSize);

    _logger
        .i("✅ Generated ${chunks.length} chunks from ${cleaned.length} chars");
    return chunks;
  }

  static String _performCleaning(String rawText) {
    return rawText
        .replaceAll(RegExp(r'Page \d+ of \d+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\n\s*\d+\s*\n'), '\n')
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'NCERT.*Class \d+', caseSensitive: false), '')
        .trim();
  }

  static List<String> _performChunking(String cleaned, int chunkSize) {
    List<String> chunks = [];
    int start = 0;
    int textLength = cleaned.length;

    while (start < textLength) {
      if (textLength - start <= chunkSize) {
        String finalChunk = cleaned.substring(start).trim();
        if (finalChunk.isNotEmpty) {
          chunks.add(finalChunk);
        }
        break;
      }

      int end = start + chunkSize;
      int splitIndex = _findSafeSplitPoint(cleaned, end, chunkSize);

      if (splitIndex <= start) {
        splitIndex = end;
      }

      String chunk = cleaned.substring(start, splitIndex).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }

      start = splitIndex;
    }

    return chunks;
  }

  static int _findSafeSplitPoint(String text, int end, int chunkSize) {
    int searchZone = (chunkSize * searchZonePercentage).toInt();

    int paragraphBreak = text.lastIndexOf('\n\n', end);
    if (paragraphBreak != -1 && paragraphBreak > (end - searchZone)) {
      return paragraphBreak + 2;
    }

    int lineBreak = text.lastIndexOf('\n', end);
    if (lineBreak != -1 && lineBreak > (end - searchZone)) {
      return lineBreak + 1;
    }

    int dot = text.lastIndexOf('.', end);
    int exclamation = text.lastIndexOf('!', end);
    int question = text.lastIndexOf('?', end);

    int sentenceEnd = [dot, exclamation, question]
        .reduce((curr, next) => curr > next ? curr : next);

    if (sentenceEnd != -1 && sentenceEnd > (end - searchZone)) {
      return sentenceEnd + 1;
    }

    int space = text.lastIndexOf(' ', end);
    if (space != -1 && space > (end - searchZone)) {
      return space + 1;
    }

    return end;
  }

  static bool isChunkValid(String chunk) {
    return chunk.trim().length >= 100 && chunk.split(' ').length >= 15;
  }
}
