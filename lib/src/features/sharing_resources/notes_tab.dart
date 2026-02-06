import 'package:flutter/material.dart';

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = [
      {
        "title": "Photosynthesis Notes",
        "class": "Class 6",
        "subject": "Science",
        "chapter": "Chapter 5",
        "topic": "Photosynthesis",
        "type": "PDF",
        "teacher": "Mrs. Mary",
        "time": "10 mins ago",
      },
      {
        "title": "Ecosystem Video",
        "class": "Class 6",
        "subject": "Science",
        "chapter": "Chapter 4",
        "topic": "Ecosystem",
        "type": "Video Link",
        "teacher": "Mrs. Mary",
        "time": "1 hr ago",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final n = notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              n["type"] == "PDF" ? Icons.picture_as_pdf : Icons.video_library,
              color: Colors.indigo,
            ),
            title: Text(n["title"]!),
            subtitle: Text(
              "${n["class"]}, ${n["subject"]}\n${n["chapter"]} • ${n["topic"]}",
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(n["teacher"]!, style: const TextStyle(fontSize: 12)),
                Text(n["time"]!, style: const TextStyle(fontSize: 11)),
              ],
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Downloading resource...")),
              );
            },
          ),
        );
      },
    );
  }
}
