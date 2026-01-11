import 'package:flutter/material.dart';

class ConnectTeacher extends StatelessWidget {
  const ConnectTeacher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect with Teacher')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Select Teacher',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Class & subject filter will appear here'),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Meeting Preference',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Physical meet or virtual meet selection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
