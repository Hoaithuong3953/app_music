import 'package:flutter/material.dart';

class PlaylistCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const PlaylistCard({super.key, required this.imagePath, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Image.asset(imagePath, height: 120, width: 150, fit: BoxFit.cover),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
