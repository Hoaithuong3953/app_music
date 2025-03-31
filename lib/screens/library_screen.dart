import 'package:flutter/material.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String selectedFilter = "Playlists"; // Trạng thái filter được chọn

  final List<Map<String, dynamic>> libraryItems = [
    {"icon": Icons.favorite, "title": "Liked Songs", "subtitle": "Playlist • 348 songs"},
    {"icon": Icons.notifications, "title": "New Episodes", "subtitle": "Playlist • 25 songs"},
    {"icon": Icons.music_note, "title": "Movie Soundtrack", "subtitle": "Playlist • 18 songs"},
    {"icon": Icons.person, "title": "BTS", "subtitle": "Playlist • 124 songs"},
    {"icon": Icons.music_note, "title": "Chill Hits", "subtitle": "Playlist • 200 songs"},
    {"icon": Icons.person, "title": "Austin Mahone", "subtitle": "Playlist • 56 songs"},
    {"icon": Icons.library_music, "title": "Relaxing Hits", "subtitle": "Playlist • 150 songs"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền nhẹ nhàng
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Library",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28, color: Color(0xFFA6B9FF)),
            onPressed: () {
              // TODO: Thêm logic tìm kiếm trong library
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 28, color: Color(0xFFA6B9FF)),
            onPressed: () {
              // TODO: Thêm logic tạo playlist mới
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Recently Played",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: libraryItems.length,
                itemBuilder: (context, index) {
                  final item = libraryItems[index];
                  return _buildLibraryItem(
                    icon: item['icon'],
                    title: item['title'],
                    subtitle: item['subtitle'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = label;
            // TODO: Lọc danh sách dựa trên filter
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFA6B9FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFA6B9FF),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFA6B9FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Điều hướng đến chi tiết playlist/artist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Selected: $title")),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFA6B9FF).withOpacity(0.9),
                    const Color(0xFFA6B9FF).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA6B9FF).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}