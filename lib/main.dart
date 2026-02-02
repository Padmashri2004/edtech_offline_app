import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// ROOT APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeMenuPage(),
    );
  }
}

/// HOME MENU
class HomeMenuPage extends StatelessWidget {
  const HomeMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            menuButton(context, "Learning Feed", const LearningFeedPage()),
            menuButton(
              context,
              "Assignment Viewer",
              const AssignmentViewerPage(),
            ),
            menuButton(context, "Image Match", const ImageMatchDemoPage()),
            menuButton(context, "Rewards", const RewardsDemoPage()),
          ],
        ),
      ),
    );
  }

  Widget menuButton(BuildContext context, String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Text(title),
      ),
    );
  }
}

//////////////////////////////////////////////////////////
/// LEARNING FEED PAGE
//////////////////////////////////////////////////////////

class LearningFeedPage extends StatefulWidget {
  const LearningFeedPage({super.key});

  @override
  State<LearningFeedPage> createState() => _LearningFeedPageState();
}

class _LearningFeedPageState extends State<LearningFeedPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> posts = [];

  void addPost() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        posts.insert(0, _controller.text);
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Learning Feed")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Share something...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: addPost),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (_, i) =>
                  Card(child: ListTile(title: Text(posts[i]))),
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////
/// ASSIGNMENT VIEWER
//////////////////////////////////////////////////////////

class AssignmentViewerPage extends StatelessWidget {
  const AssignmentViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assignment Viewer")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Scanning document...")),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Scan Assignment"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Message sent to teacher")),
                );
              },
              icon: const Icon(Icons.message),
              label: const Text("Ask Doubt"),
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////
/// IMAGE MATCH (SERVICE + PAGE)
//////////////////////////////////////////////////////////

class ImageMatchService {
  static final Map<String, String> imageMap = {
    "plant": "🌱",
    "heart": "❤️",
    "photosynthesis": "☀️🌿",
  };

  static String? getImageForText(String text) {
    for (final key in imageMap.keys) {
      if (text.toLowerCase().contains(key)) {
        return imageMap[key];
      }
    }
    return null;
  }
}

class ImageMatchDemoPage extends StatefulWidget {
  const ImageMatchDemoPage({super.key});

  @override
  State<ImageMatchDemoPage> createState() => _ImageMatchDemoPageState();
}

class _ImageMatchDemoPageState extends State<ImageMatchDemoPage> {
  final TextEditingController _controller = TextEditingController();
  String? result;

  void findImage() {
    setState(() {
      result = ImageMatchService.getImageForText(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image Match")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter keyword (plant, heart...)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: findImage, child: const Text("Match")),
            const SizedBox(height: 20),
            Text(result ?? "No match", style: const TextStyle(fontSize: 40)),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////
/// REWARDS (WIDGET + PAGE)
//////////////////////////////////////////////////////////

class RewardsBadgeWidget extends StatelessWidget {
  final int points;

  const RewardsBadgeWidget({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.emoji_events,
          size: 60,
          color: points >= 50 ? Colors.amber : Colors.grey,
        ),
        const SizedBox(height: 8),
        Text("$points Points"),
        if (points >= 50) const Text("Gold Contributor 🏆"),
      ],
    );
  }
}

class RewardsDemoPage extends StatefulWidget {
  const RewardsDemoPage({super.key});

  @override
  State<RewardsDemoPage> createState() => _RewardsDemoPageState();
}

class _RewardsDemoPageState extends State<RewardsDemoPage> {
  int points = 0;

  void addPoints() {
    setState(() => points += 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rewards")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RewardsBadgeWidget(points: points),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addPoints,
              child: const Text("Add Points"),
            ),
          ],
        ),
      ),
    );
  }
}
