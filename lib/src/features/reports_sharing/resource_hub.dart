import 'package:flutter/material.dart';

class ResourceHub extends StatelessWidget {
  const ResourceHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resource Hub')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Shared Resources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Notes, PDFs, videos shared by teachers'),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Assignments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Assignments with deadlines will appear here'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
