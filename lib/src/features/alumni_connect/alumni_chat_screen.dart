import 'package:flutter/material.dart';
import 'models/alumni_model.dart';
import 'widgets/message_bubble.dart';

class AlumniChatScreen extends StatefulWidget {
  final AlumniModel alumni;

  const AlumniChatScreen({
    super.key,
    required this.alumni,
  });

  @override
  State<AlumniChatScreen> createState() => _AlumniChatScreenState();
}

class _AlumniChatScreenState extends State<AlumniChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.alumni.name}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MessageBubble(text: "Hi!", isMe: false),
                MessageBubble(text: "Hello 👋", isMe: true),
              ],
            ),
          ),
          _inputBox(),
        ],
      ),
    );
  }

  Widget _inputBox() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _controller.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Message sent")),
              );
            },
          ),
        ],
      ),
    );
  }
}
