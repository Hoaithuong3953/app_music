import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../service/song_service.dart';
import '../service/user_service.dart';
import '../service/album_service.dart';
import '../widgets/artist_card.dart';
import '../widgets/song_card.dart';
import '../widgets/album_card.dart'; // Đảm bảo import đúng
import '../providers/audio_provider.dart';
import 'song_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = "Loading...";
  List<Song> _songs = [];
  List<Album> _albums = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSongs();
    _loadAlbums();
  }

  Future<void> _loadUserInfo() async {
    try {
      const String baseUrl = "http://10.0.2.2:8080";
      final userService = UserService(baseUrl: baseUrl);
      final user = await userService.getCurrentUser();
      setState(() {
        _username = user.firstName;
      });
    } catch (e) {
      print("Không thể lấy thông tin người dùng: $e");
      setState(() {
        _username = "User";
      });
    }
  }

  Future<void> _loadSongs() async {
    final songService = SongService();
    final fetchedSongs = await songService.fetchSongs();
    setState(() {
      _songs = fetchedSongs;
    });
    Provider.of<AudioProvider>(context, listen: false).setSongs(
      fetchedSongs.map((song) => {
        'songUrl': song.url ?? '',
        'title': song.title,
        'artist': song.artist?.name ?? 'Unknown Artist',
        'imagePath': song.coverImage ?? 'default_image_url',
      }).toList(),
    );
  }

  Future<void> _loadAlbums() async {
    final albumService = AlbumService();
    final fetchedAlbums = await albumService.fetchAlbums();
    setState(() {
      _albums = fetchedAlbums;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        onRefresh: () async {
          await _loadUserInfo();
          await _loadSongs();
          await _loadAlbums();
        },
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
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: "Search music",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Color(0xFFA6B9FF)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Popular Albums
                _buildSectionHeader("Popular Albums", onViewAll: () {}),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: _albums.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _albums.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final album = _albums[index];
                      return AlbumCard(
                        imagePath: album.coverImageUrl ?? 'https://via.placeholder.com/120',
                        title: album.title,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Recommended Songs
                _buildSectionHeader("Recommended Songs", onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SongListScreen()),
                  );
                }),
                const SizedBox(height: 12),
                Consumer<AudioProvider>(
                  builder: (context, audioProvider, child) {
                    final songs = audioProvider.songs;
                    if (songs.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Column(
                      children: (songs.length <= 7 ? songs : songs.sublist(0, 7)).map((song) {
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
                    );
                  },
                ),
              ],
            ),
          ),
        ),
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