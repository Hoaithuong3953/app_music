import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../service/genre_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GenreService genreService = GenreService();
  List<dynamic> genres = [];
  bool isLoading = true;
  final Random _random = Random();
  Map<String, Color> genreColors = {};

  // Danh sách màu sắc đậm hơn, đồng bộ với theme
  final List<Color> availableColors = [
    const Color(0xFFA6B9FF), // Theme primary
    const Color(0xFFB71C1C), // Deep Red
    const Color(0xFFD84315), // Burnt Orange
    const Color(0xFF00796B), // Dark Teal
    const Color(0xFF01579B), // Dark Blue
    const Color(0xFF4A148C), // Dark Purple
    const Color(0xFF880E4F), // Dark Pink
    const Color(0xFF1DB954), // Spotify Green
  ];

  @override
  void initState() {
    super.initState();
    fetchGenres();
  }

  Future<void> fetchGenres() async {
    try {
      final data = await genreService.getGenres();
      setState(() {
        genres = data;
        isLoading = false;
      });
      await loadGenreColors();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  Future<void> loadGenreColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedColors = prefs.getString('genreColors');

    if (storedColors != null) {
      Map<String, dynamic> savedColors = jsonDecode(storedColors);
      setState(() {
        genreColors = savedColors.map((key, value) => MapEntry(key, Color(value)));
      });
    } else {
      for (var genre in genres) {
        genreColors.putIfAbsent(
          genre['name'],
              () => availableColors[_random.nextInt(availableColors.length)],
        );
      }
      await saveGenreColors();
    }
  }

  Future<void> saveGenreColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, int> colorMap = genreColors.map((key, value) => MapEntry(key, value.value));
    await prefs.setString('genreColors', jsonEncode(colorMap));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền nhẹ nhàng
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Color(0xFFA6B9FF)),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Browse Genres",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: genres.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.8, // Tăng chiều ngang nhẹ
                ),
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  final genreColor = genreColors[genre['name']] ?? Colors.blueGrey;

                  return GestureDetector(
                    onTap: () {
                      // TODO: Điều hướng hoặc xử lý khi nhấn vào genre
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Selected: ${genre['name']}")),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            genreColor.withOpacity(0.9),
                            genreColor.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: genreColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            genre['name'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}