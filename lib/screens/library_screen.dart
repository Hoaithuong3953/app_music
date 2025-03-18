import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              "Library",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("Playlists"),
                _buildFilterChip("Podcasts"),
                _buildFilterChip("Albums"),
                _buildFilterChip("Artists"),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              "Recently Played",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  _buildLibraryItem(Icons.favorite, "Liked Songs", "Playlist • 348 songs"),
                  _buildLibraryItem(Icons.notifications, "New Episodes", "Playlist • 25 songs"),
                  _buildLibraryItem(Icons.music_note, "Movie Soundtrack", "Playlist • 18 songs"),
                  _buildLibraryItem(Icons.person, "BTS", "Playlist • 124 songs"),
                  _buildLibraryItem(Icons.music_note, "Chill Hits", "Playlist • 200 songs"),
                  _buildLibraryItem(Icons.person, "Austin Mahone", "Playlist • 56 songs"),
                  _buildLibraryItem(Icons.library_music, "Relaxing Hits", "Playlist • 150 songs"),
                ],

              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor: const Color(0xFFA6B9FF), // Theme color
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildLibraryItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 70, // Increased for better layout
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
