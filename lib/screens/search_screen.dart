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
  Map<String, Color> genreColors = {}; // Lưu màu cố định

  // Danh sách màu sắc đậm hơn để chữ trắng dễ nhìn
  final List<Color> availableColors = [
    Color(0xFF1DB954), // Spotify Green
    Color(0xFFB71C1C), // Deep Red
    Color(0xFFD84315), // Burnt Orange
    Color(0xFF00796B), // Dark Teal
    Color(0xFF01579B), // Dark Blue
    Color(0xFF4A148C), // Dark Purple
    Color(0xFF880E4F), // Dark Pink
    Color(0xFF3E2723), // Dark Brown
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
        genreColors = savedColors.map((key, value) =>
            MapEntry(key, Color(value))); // Convert lại từ int sang Color
      });
    } else {
      // Nếu chưa có, tạo mới màu random
      for (var genre in genres) {
        genreColors.putIfAbsent(
            genre['name'], () => availableColors[_random.nextInt(availableColors.length)]);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200], // Giữ nguyên màu của thanh search
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: genres.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          itemBuilder: (context, index) {
            final genre = genres[index];
            return Container(
              decoration: BoxDecoration(
                color: genreColors[genre['name']] ?? Colors.blueGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  genre['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
