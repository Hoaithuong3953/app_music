import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/genre.dart';
import '../service/genre_service.dart';
import '../service/song_service.dart';
import '../providers/search_provider.dart';
import '../widgets/genre_grid.dart';
import '../widgets/search_results.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GenreService genreService = GenreService();
  final SongService songService = SongService();
  List<Genre> genres = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, Color> genreColors = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
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
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = null;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Không thể tải thể loại và bài hát: $e';
        });
      }
    }
  }

  Future<void> _loadGenreColors() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedColors = prefs.getString('genreColors');
      if (storedColors != null) {
        Map<String, int> colorMap = Map<String, int>.from(jsonDecode(storedColors));
        if (mounted) {
          setState(() {
            genreColors = colorMap.map((key, value) => MapEntry(key, Color(value)));
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải màu thể loại: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
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
            gradient: LinearGradient(
              colors: [
                const Color(0xFFA6B9FF).withOpacity(0.2),
                const Color(0xFF1DB954).withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFA6B9FF).withOpacity(0.5),
              width: 2,
            ),
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
                    hintText: "Bạn muốn nghe gì?",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFFB71C1C)),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SearchProvider>().updateSearchQuery('');
                        FocusScope.of(context).unfocus();
                      },
                    )
                        : null,
                  ),
                  style: const TextStyle(color: Colors.black),
                  onSubmitted: (value) {
                    context.read<SearchProvider>().updateSearchQuery(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA6B9FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _searchController.text.isEmpty
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thể loại',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    genres.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Không có thể loại nào',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                        : GenreGrid(genres: genres, genreColors: genreColors),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kết quả tìm kiếm',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SearchResults(filteredSongs: searchProvider.filteredSongs),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}