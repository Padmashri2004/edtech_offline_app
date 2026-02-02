import 'package:flutter/material.dart';

class LearningFeedPage extends StatefulWidget {
  const LearningFeedPage({super.key});

  @override
  State<LearningFeedPage> createState() => _LearningFeedPageState();
}

class _LearningFeedPageState extends State<LearningFeedPage> {
  final TextEditingController _postController = TextEditingController();
  final List<String> posts = [];

  void addPost() {
    if (_postController.text.isNotEmpty) {
      setState(() {
        posts.insert(0, _postController.text);
        _postController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Learnings"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: "Share a tip or trick...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigo),
                  onPressed: addPost,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb, color: Colors.orange),
                    title: Text(posts[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
