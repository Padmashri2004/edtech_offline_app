import 'package:flutter/material.dart';
import '../models/learning_post_model.dart';

class LearningPostCard extends StatelessWidget {
  final LearningPost post;

  const LearningPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      post.className,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(post.badge),
                  backgroundColor: Colors.orange.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "${post.subject} • ${post.chapter} • ${post.topic}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
