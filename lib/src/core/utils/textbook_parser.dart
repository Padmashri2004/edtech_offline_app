import 'package:logger/logger.dart';

class TextbookParser {
  final Logger _logger = Logger();

  /// Parse raw textbook text into structured chapters and topics
  List<Map<String, dynamic>> parseTextbook(String rawText) {
    List<Map<String, dynamic>> chapters = [];
    try {
      if (rawText.isEmpty) return [];

      // Split into lines for scanning
      final lines = rawText.split('\n');

      RegExp chapterRegex =
          RegExp(r'^\s*Chapter\s+(\d+):?\s*(.*)$', caseSensitive: false);
      RegExp topicRegex =
          RegExp(r'^\s*(\d+\.\d+)\s+(.+)$'); // e.g., "1.1 Introduction"

      Map<String, dynamic>? currentChapter;

      for (String line in lines) {
        String trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.length > 200) continue;

        // Detect chapter headings
        final chapterMatch = chapterRegex.firstMatch(trimmed);
        if (chapterMatch != null) {
          if (currentChapter != null) {
            chapters.add(currentChapter);
          }
          currentChapter = {
            'chapterNumber': chapterMatch.group(1),
            'title': chapterMatch.group(2)?.trim() ?? '',
            'topics': <Map<String, String>>[]
          };
          continue;
        }

        // Detect topics/subtopics
        final topicMatch = topicRegex.firstMatch(trimmed);
        if (topicMatch != null && currentChapter != null) {
          currentChapter['topics'].add({
            'topicNumber': topicMatch.group(1)!,
            'title': topicMatch.group(2)!.trim(),
          });
        }
      }

      // Add last chapter if exists
      if (currentChapter != null) {
        chapters.add(currentChapter);
      }

      return chapters;
    } catch (e) {
      _logger.e("❌ Error parsing textbook: $e");
      return [];
    }
  }

  /// Utility: flatten topics into a list of strings for AI prompt building
  List<String> extractTopics(List<Map<String, dynamic>> chapters) {
    try {
      List<String> topics = [];
      for (var chapter in chapters) {
        for (var topic in (chapter['topics'] as List<Map<String, String>>)) {
          topics.add(
              "${chapter['chapterNumber']}.${topic['topicNumber']} ${topic['title']}");
        }
      }
      return topics;
    } catch (e) {
      _logger.e("❌ Error extracting topics: $e");
      return [];
    }
  }
}
