import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/genre.dart';
import '../service/genre_service.dart';
import '../service/song_service.dart';
import '../providers/search_provider.dart';  // Import SearchProvider
import '../widgets/genre_grid.dart';
import '../widgets/search_results.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GenreService genreService = GenreService();
  final SongService songService = SongService();
  List<Genre> genres = [];
  bool isLoading = true;
  Map<String, Color> genreColors = {};

  @override
  void initState() {
    super.initState();
    fetchData();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SearchProvider>().updateSearchQuery(widget.initialQuery!);
      });
    }
    _searchController.addListener(() {
      context.read<SearchProvider>().updateSearchQuery(_searchController.text);
    });
  }

  Future<void> fetchData() async {
    try {
      genres = await genreService.getGenres();
      final songs = await songService.fetchSongs();
      context.read<SearchProvider>().setSongs(songs);
      await _loadGenreColors();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadGenreColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedColors = prefs.getString('genreColors');
    if (storedColors != null) {
      Map<String, int> colorMap = Map<String, int>.from(jsonDecode(storedColors));
      setState(() {
        genreColors = colorMap.map((key, value) => MapEntry(key, Color(value)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
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
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFFA6B9FF)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "What do you want to listen to?",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                        : null,
                  ),
                  style: const TextStyle(color: Colors.black),
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
            if (_searchController.text.isEmpty) ...[
              const Text(
                "Browse Genres",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              GenreGrid(genres: genres, genreColors: genreColors),
            ],
            if (_searchController.text.isNotEmpty) ...[
              const Text(
                "Search Results",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Expanded(child: SearchResults(filteredSongs: searchProvider.filteredSongs)),
            ],
          ],
        ),
      ),
    );
  }
}
