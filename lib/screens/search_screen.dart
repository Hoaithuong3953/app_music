import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "What do you want to listen to?",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7, // Điều chỉnh kích thước danh mục
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              decoration: BoxDecoration(
                color: category['color'],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  category['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18, // Phóng to chữ
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> categories = [
  {"title": "Music", "color": Colors.blue},
  {"title": "Podcasts", "color": Colors.green},
  {"title": "Live Events", "color": Colors.deepPurple},
  {"title": "For You", "color": Colors.orange},
  {"title": "New Releases", "color": Colors.pink},
  {"title": "Vietnamese Music", "color": Colors.teal},
  {"title": "Pop", "color": Colors.cyan},
  {"title": "K-Pop", "color": Colors.red},
  {"title": "Hip-Hop", "color": Colors.amber},
  {"title": "Podcast Rankings", "color": Colors.blueAccent},
  {"title": "Education", "color": Colors.indigo},
  {"title": "Documents", "color": Colors.purpleAccent},
  {"title": "Trending Now", "color": Colors.lightBlue},
  {"title": "Chill Vibes", "color": Colors.deepOrange},
];
