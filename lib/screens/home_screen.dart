import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/user.dart';
import '../service/song_service.dart';
import '../service/user_service.dart';
import '../service/album_service.dart';
import '../widgets/song_card.dart';
import '../widgets/album_card.dart';
import '../providers/audio_provider.dart';
import '../providers/search_provider.dart';
import 'search_screen.dart';
import 'song_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = "Loading...";
  List<Album> _albums = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      const String baseUrl = "http://10.0.2.2:8080";
      final userService = UserService(baseUrl: baseUrl);
      final songService = SongService();
      final albumService = AlbumService();

      final results = await Future.wait([
        userService.getCurrentUser(),
        songService.fetchSongs(),
        albumService.fetchAlbums(),
      ]);

      final user = results[0] as User;
      final fetchedSongs = results[1] as List<Song>;
      final fetchedAlbums = results[2] as List<Album>;

      setState(() {
        _username = user.firstName;
        _albums = fetchedAlbums;
      });

      Provider.of<AudioProvider>(context, listen: false).setSongs(
        fetchedSongs.map((song) => {
          'songUrl': song.url ?? '',
          'title': song.title,
          'artist': song.artist?.name ?? 'Unknown Artist',
          'imagePath': song.coverImage ?? 'default_image_url',
        }).toList(),
      );

      Provider.of<SearchProvider>(context, listen: false).setSongs(fetchedSongs);
    } catch (e) {
      print("Không thể tải dữ liệu: $e");
      setState(() {
        _username = "User";
      });
    }
  }

  void _navigateToSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchScreen(initialQuery: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);
    final isSearching = _searchController.text.isNotEmpty;
    final filteredSongs = searchProvider.filteredSongs;
    final recommendedSongs = audioProvider.songs;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 80,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, color: Color(0xFFA6B9FF), size: 30),
            const SizedBox(width: 8),
            const Text("Hi, ", style: TextStyle(fontSize: 24, color: Colors.black)),
            Text(
              _username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh tìm kiếm
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search music",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: Color(0xFFA6B9FF)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          searchProvider.updateSearchQuery("");
                        },
                      )
                          : null,
                    ),
                    onChanged: (value) {
                      searchProvider.updateSearchQuery(value);
                    },
                    onSubmitted: (_) => _navigateToSearch(),
                  ),
                ),
                const SizedBox(height: 24),

                if (isSearching) ...[
                  // Kết quả tìm kiếm
                  _buildSectionHeader("Search Results"),
                  const SizedBox(height: 12),
                  filteredSongs.isEmpty
                      ? const Center(child: Text("No results found"))
                      : Column(
                    children: filteredSongs.map((song) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SongCard(
                          imagePath: song.coverImage ?? 'default_image_url',
                          title: song.title,
                          artist: song.artist?.name ?? 'Unknown Artist',
                          songUrl: song.url ?? '',
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  // Popular Albums
                  _buildSectionHeader("Popular Albums"),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: _albums.isEmpty
                        ? const Center(child: Text("No albums available"))
                        : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _albums.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return AlbumCard(
                          imagePath: album.coverImageUrl ?? 'https://via.placeholder.com/160x200',
                          title: album.title,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recommended Songs
                  _buildSectionHeader("Recommended Songs"),
                  const SizedBox(height: 12),
                  recommendedSongs.isEmpty
                      ? const Center(child: Text("No songs available"))
                      : Column(
                    children: (recommendedSongs.length <= 7 ? recommendedSongs : recommendedSongs.sublist(0, 7))
                        .map((song) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SongCard(
                          imagePath: song['imagePath'] ?? 'default_image_url',
                          title: song['title'] ?? 'Unknown Title',
                          artist: song['artist'] ?? 'Unknown Artist',
                          songUrl: song['songUrl'] ?? '',
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
