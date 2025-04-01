import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/genre.dart';

class GenreGrid extends StatefulWidget {
  final List<Genre> genres;
  final Map<String, Color> genreColors;

  const GenreGrid({super.key, required this.genres, required this.genreColors});

  @override
  _GenreGridState createState() => _GenreGridState();
}

class _GenreGridState extends State<GenreGrid> {
  final List<Color> availableColors = [
    const Color(0xFFA6B9FF),
    const Color(0xFFB71C1C),
    const Color(0xFFD84315),
    const Color(0xFF00796B),
    const Color(0xFF01579B),
    const Color(0xFF4A148C),
    const Color(0xFF880E4F),
    const Color(0xFF1DB954),
  ];

  late Map<String, Color> genreColors;

  @override
  void initState() {
    super.initState();
    genreColors = widget.genreColors; // Lấy từ widget cha
    _assignColorsIfNeeded();
  }

  void _assignColorsIfNeeded() {
    final Random random = Random();
    bool updated = false;

    for (var genre in widget.genres) {
      if (!genreColors.containsKey(genre.name)) {
        genreColors[genre.name] = availableColors[random.nextInt(availableColors.length)];
        updated = true;
      }
    }

    if (updated) {
      _saveGenreColors();
    }

    setState(() {});
  }

  Future<void> _saveGenreColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, int> colorMap = genreColors.map((key, value) => MapEntry(key, value.value));
    await prefs.setString('genreColors', jsonEncode(colorMap));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true, // Thêm shrinkWrap để GridView không chiếm hết không gian
          physics: const NeverScrollableScrollPhysics(), // Ngừng cuộn
          itemCount: widget.genres.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            final genre = widget.genres[index];
            final genreColor = genreColors[genre.name] ?? Colors.blueGrey;

            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Selected: ${genre.name}")),
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
                      genre.name,
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
      ],
    );
  }
}
