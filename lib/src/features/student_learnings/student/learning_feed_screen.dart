import 'package:flutter/material.dart';
import '../models/learning_post_model.dart';
import '../widgets/learning_post_card.dart';

class LearningFeedScreen extends StatelessWidget {
  LearningFeedScreen({super.key});

  final List<LearningPost> dummyPosts = [
    LearningPost(
      studentName: "Aarav",
      className: "Class 6 - A",
      subject: "Science",
      chapter: "Plants",
      topic: "Photosynthesis",
      content: "Remember PS: Sunlight + CO₂ + Water = Food 🌱",
      badge: "Gold",
    ),
    LearningPost(
      studentName: "Diya",
      className: "Class 7 - B",
      subject: "Math",
      chapter: "Algebra",
      topic: "Equations",
      content: "Move constants to RHS before solving!",
      badge: "Silver",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Learning Feed"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyPosts.length,
        itemBuilder: (context, index) {
          return LearningPostCard(post: dummyPosts[index]);
        },
      ),
    );
  }
}
