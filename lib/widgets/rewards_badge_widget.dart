import 'package:flutter/material.dart';

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
        Text(
          "$points Points",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (points >= 50) const Text("Gold Contributor 🏆"),
      ],
    );
  }
}
