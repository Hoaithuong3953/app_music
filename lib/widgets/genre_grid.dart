import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/genre.dart';
import '../screens/genre_detail_screen.dart';

class GenreGrid extends StatefulWidget {
  final List<Genre> genres;
  final Map<String, Color> genreColors;

  const GenreGrid({super.key, required this.genres, required this.genreColors});

  @override
  _GenreGridState createState() => _GenreGridState();
}

class _GenreGridState extends State<GenreGrid> with TickerProviderStateMixin {
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
  final Map<int, AnimationController> _animationControllers = {};

  @override
  void initState() {
    super.initState();
    genreColors = Map.from(widget.genreColors);
    _loadGenreColors().then((_) => _assignColorsIfNeeded());
    for (int i = 0; i < widget.genres.length; i++) {
      _animationControllers[i] = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
        lowerBound: 0.95,
        upperBound: 1.0,
      );
    }
  }

  Future<void> _loadGenreColors() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedColors = prefs.getString('genreColors');
      if (savedColors != null && genreColors.isEmpty) {
        Map<String, dynamic> colorMap = jsonDecode(savedColors);
        genreColors = colorMap.map((key, value) => MapEntry(key, Color(value)));
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading genre colors: $e');
    }
  }

  void _assignColorsIfNeeded() {
    final Random random = Random();
    bool updated = false;

    for (var genre in widget.genres) {
      final genreTitle = genre.title ?? 'Unknown Genre';
      if (!genreColors.containsKey(genreTitle)) {
        genreColors[genreTitle] = availableColors[random.nextInt(availableColors.length)];
        updated = true;
      }
    }

    if (updated) {
      _saveGenreColors();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _saveGenreColors() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, int> colorMap = genreColors.map((key, value) => MapEntry(key, value.value));
      await prefs.setString('genreColors', jsonEncode(colorMap));
    } catch (e) {
      debugPrint('Error saving genre colors: $e');
    }
  }

  @override
  void dispose() {
    _animationControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.genres.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final genre = widget.genres[index];
        final genreColor = genreColors[genre.title ?? 'Unknown Genre'] ?? Colors.blueGrey;
        final animationController = _animationControllers[index]!;

        return GestureDetector(
          onTapDown: (_) {
            animationController.forward();
          },
          onTapUp: (_) {
            animationController.reverse();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenreDetailScreen(genre: genre),
              ),
            );
          },
          onTapCancel: () {
            animationController.reverse();
          },
          child: ScaleTransition(
            scale: animationController,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: genreColor.withOpacity(0.6),
                    blurRadius: 14,
                    spreadRadius: 3,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: animationController.isAnimating
                        ? genreColor.withOpacity(0.5)
                        : Colors.transparent,
                    blurRadius: 22,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient đậm
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            genreColor.withOpacity(1.0),
                            genreColor.withOpacity(0.9),
                            genreColor.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    // Glassmorphism overlay
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        backgroundBlendMode: BlendMode.overlay,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    // Ảnh bìa hoặc placeholder
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Transform.rotate(
                        angle: -0.1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (genre.coverImage != null && genre.coverImage!.trim().isNotEmpty)
                                ? CachedNetworkImage(
                              imageUrl: genre.coverImage!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: genreColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: genreColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            )
                                : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: genreColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Tiêu đề thể loại với màu đen
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          genre.title ?? 'Unknown Genre',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.white54,
                                offset: Offset(1, 1),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}