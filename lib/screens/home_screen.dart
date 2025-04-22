import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/user.dart';
import '../service/song_service.dart';
import '../service/user_service.dart';
import '../service/album_service.dart';
import '../widgets/album_card.dart';
import '../widgets/artist_card.dart';
import '../providers/audio_provider.dart';
import '../providers/search_provider.dart';
import '../providers/artist_provider.dart';
import 'now_playing_screen.dart';
import 'search_screen.dart';
import 'song_list_screen.dart';

// Định nghĩa SongCard trực tiếp trong home_screen.dart
class SongCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String artist;
  final String songUrl;

  const SongCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.artist,
    required this.songUrl,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imagePath,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        artist,
        style: const TextStyle(fontSize: 14, color: Colors.black54),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Semantics(
        label: 'play_song_button', // Để Appium nhận diện
        child: IconButton(
          icon: const Icon(Icons.play_arrow, color: Color(0xFFA6B9FF)),
          onPressed: () {
            // Gọi hàm phát nhạc từ AudioProvider
            audioProvider.playSong({
              'songUrl': songUrl,
              'title': title,
              'artist': artist,
              'imagePath': imagePath,
            });
          },
        ),
      ),
      onTap: () {
        // Nhấn vào toàn bộ SongCard để mở NowPlayingScreen
        audioProvider.playSong({
          'songUrl': songUrl,
          'title': title,
          'artist': artist,
          'imagePath': imagePath,
        });
        // Điều hướng đến NowPlayingScreen (nếu cần)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
        );
      },
    );
  }
}

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

  Future<void> _loadData() async {
    try {
      const String baseUrl = "http://10.0.2.2:8080";
      final userService = UserService(baseUrl: baseUrl);
      final songService = SongService();
      final albumService = AlbumService();

      final artistProvider = Provider.of<ArtistProvider>(context, listen: false);
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);

      final results = await Future.wait([
        userService.getCurrentUser(),
        songService.fetchSongs(),
        albumService.fetchAlbums(),
        artistProvider.fetchArtists(),
      ]);

      final user = results[0] as User;
      final fetchedSongs = results[1] as List<Song>;
      final fetchedAlbums = results[2] as List<Album>;

      setState(() {
        _username = user.firstName;
        _albums = fetchedAlbums;
      });

      // Debug dữ liệu bài hát
      print("Fetched Songs: ${fetchedSongs.map((song) => {'title': song.title, 'artist': song.artist?.id ?? song.artist}).toList()}");

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

      print("Songs for AudioProvider: $songsForProvider"); // Debug
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
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      _buildSectionHeader("Popular Albums", onViewAll: () {}),
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

                      _buildSectionHeader("Popular Artists", onViewAll: () {}),
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
                        children: (recommendedSongs.length <= 7
                            ? recommendedSongs
                            : recommendedSongs.sublist(0, 7))
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