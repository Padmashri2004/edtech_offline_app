class Textbook {
  final String title;
  final List<Chapter> chapters;

  Textbook({required this.title, required this.chapters});
}

class Chapter {
  final String title;
  final int startPage;
  final int endPage;
  // This helps the AI focus on specific parts of a chapter
  final List<String>? subTopics; 

  Chapter({
    required this.title, 
    required this.startPage, 
    required this.endPage,
    this.subTopics,
  });
}