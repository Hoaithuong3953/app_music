import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/user.dart';
import '../service/song_service.dart';
import '../service/user_service.dart';
import '../service/album_service.dart';
import '../widgets/song_card.dart';
import '../widgets/album_card.dart';
import '../widgets/artist_card.dart';
import '../providers/audio_provider.dart';
import '../providers/search_provider.dart';
import '../providers/artist_provider.dart';
import 'search_screen.dart';
import 'song_list_screen.dart';
import 'album_list_screen.dart';
import 'login_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<User?> _loadUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    }
    return null;
  }

  Future<User?> _fetchUser() async {
    const String baseUrl = "http://10.0.2.2:8080";
    final userService = UserService(baseUrl: baseUrl);
    User? user = await userService.getCurrentUser();

    if (user == null) {
      debugPrint("User is null from API. Trying to load from SharedPreferences.");
      user = await _loadUserFromPreferences();
    }

    return user;
  }

  Future<void> _loadData() async {
    try {
      // Lấy thông tin người dùng
      User? user = await _fetchUser();

      if (user == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      // Lấy dữ liệu bài hát và album
      final songService = SongService();
      final albumService = AlbumService();
      final artistProvider = Provider.of<ArtistProvider>(context, listen: false);
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);

      List<Song> fetchedSongs = [];
      List<Album> fetchedAlbums = [];

      try {
        fetchedSongs = await songService.fetchSongs();
      } catch (e) {
        debugPrint("Failed to fetch songs: $e");
      }

      try {
        fetchedAlbums = await albumService.fetchAlbums();
      } catch (e) {
        debugPrint("Failed to fetch albums: $e");
      }

      try {
        await artistProvider.fetchArtists();
      } catch (e) {
        debugPrint("Failed to fetch artists: $e");
      }

      // Cập nhật state
      setState(() {
        _username = user.firstName.trim().isNotEmpty
            ? user.firstName
            : (user.email.trim().isNotEmpty
            ? user.email
            : "User");
        _albums = fetchedAlbums;
      });

      // Cập nhật AudioProvider với tên ca sĩ từ ArtistProvider
      final songsForProvider = fetchedSongs.map((song) {
        String artistName;
        if (song.artist == null) {
          artistName = 'Unknown Artist';
        } else {
          artistName = artistProvider.getArtistNameById(song.artist!.id);
        }
        return {
          'songUrl': song.url ?? '',
          'title': song.title,
          'artist': artistName,
          'imagePath': song.coverImage ?? 'default_image_url',
        };
      }).toList();

      audioProvider.setSongs(songsForProvider);
      searchProvider.setSongs(fetchedSongs);
    } catch (e) {
      debugPrint("Unexpected error loading data: $e");
      setState(() {
        _username = "User";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
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
    final artistProvider = Provider.of<ArtistProvider>(context);
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
            Text(
              "Hi, $_username",
              style: const TextStyle(fontSize: 24, color: Colors.black),
              semanticsLabel: "Hi, $_username",
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ArtistProvider>(
        builder: (context, artistProvider, child) {
          if (artistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
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
                      _buildSectionHeader("Search Results", onViewAll: () {}),
                      const SizedBox(height: 12),
                      filteredSongs.isEmpty
                          ? const Center(child: Text("No results found"))
                          : Column(
                        children: filteredSongs.map((song) {
                          final artistName = song.artist != null
                              ? artistProvider.getArtistNameById(song.artist!.id)
                              : 'Unknown Artist';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SongCard(
                              imagePath: song.coverImage ?? 'default_image_url',
                              title: song.title,
                              artist: artistName,
                              songUrl: song.url ?? '',
                              index: audioProvider.songs.indexWhere((s) => s['songUrl'] == song.url),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      _buildSectionHeader("Popular Albums", onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AlbumListScreen()),
                        );
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: _albums.isEmpty
                            ? const Center(child: Text("No albums available"))
                            : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _albums.length > 5 ? 5 : _albums.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final album = _albums[index];
                            return AlbumCard(
                              imagePath: album.coverImageURL ?? 'https://via.placeholder.com/160x200',
                              title: album.title,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader("Popular Artists", onViewAll: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (context) => const ArtistListScreen()),
                        // );
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: artistProvider.artists.isEmpty
                            ? const Center(child: Text("No artists available"))
                            : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: artistProvider.artists.length > 5 ? 5 : artistProvider.artists.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final artist = artistProvider.artists[index];
                            return ArtistCard(
                              name: artist.title,
                              imagePath: artist.avatar ?? 'default_image_url',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader("Recommended Songs", onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SongListScreen()),
                        );
                      }),
                      const SizedBox(height: 12),
                      recommendedSongs.isEmpty
                          ? const Center(child: Text("No songs available"))
                          : Column(
                        children: recommendedSongs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final song = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SongCard(
                              imagePath: song['imagePath'] ?? 'default_image_url',
                              title: song['title'] ?? 'Unknown Title',
                              artist: song['artist'] ?? 'Unknown Artist',
                              songUrl: song['songUrl'] ?? '',
                              index: index,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Text(
            "View All",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFA6B9FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}