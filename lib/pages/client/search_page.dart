import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../models/song.dart';
import '../../service/client/song_service.dart';
import '../../widgets/client/song_tile.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SongService _songService = SongService();
  List<String> searchHistory = [];
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    Set<String> uniqueHistory = {...searchHistory, query.trim()};
    searchHistory = uniqueHistory.toList();
    await prefs.setStringList('search_history', searchHistory);
    setState(() {});
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      searchHistory = [];
    });
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
      isSearching = true;
      errorMessage = null;
    });

    try {
      final results = await _songService.getAllSongs(
        title: query.trim(),
        sort: 'title',
      );

      final seenIds = <String>{};
      final uniqueResults = results.where((songData) {
        final song = songData['song'] as Song;
        return seenIds.add(song.id);
      }).toList();

      setState(() {
        searchResults = uniqueResults;
        isLoading = false;
      });
      _saveSearchQuery(query);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _onSearch(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      searchResults = [];
      errorMessage = null;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.03, screenWidth * 0.04, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        size: screenHeight * 0.03,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search songs...',
                          filled: true,
                          fillColor: Colors.grey[200],
                          prefixIcon: Icon(
                            Icons.search,
                            size: screenHeight * 0.03,
                            color: Theme.of(context).highlightColor,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: screenHeight * 0.03,
                              color: Theme.of(context).highlightColor,
                            ),
                            onPressed: _clearSearch,
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                if (!isSearching) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Search History',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: screenHeight * 0.025,
                          color: Theme.of(context).highlightColor,
                        ),
                      ),
                      if (searchHistory.isNotEmpty)
                        TextButton(
                          onPressed: _clearSearchHistory,
                          child: Text(
                            'Clear',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: screenHeight * 0.018,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  searchHistory.isEmpty
                      ? Center(child: Text('No search history'))
                      : Expanded(
                    child: ListView.builder(
                      itemCount: searchHistory.length,
                      itemBuilder: (context, index) {
                        final query = searchHistory[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                            vertical: 0,
                          ),
                          title: Text(
                            query,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: screenHeight * 0.02,
                            ),
                          ),
                          onTap: () {
                            _searchController.text = query;
                            _onSearch(query);
                          },
                        );
                      },
                    ),
                  ),
                ] else ...[
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(child: Text('Error: $errorMessage'))
                      : searchResults.isEmpty
                      ? Center(child: Text('No results found'))
                      : Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final songData = searchResults[index];
                        final song = songData['song'] as Song;
                        final artistName = songData['artistName'] as String;
                        return SongTile(
                          song: song,
                          artistName: artistName,
                          index: index + 1,
                          isRanking: false,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}