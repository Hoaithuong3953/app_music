import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../service/song_service.dart';
import '../widgets/music_player.dart';
import 'now_playing_screen.dart';

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  _SongListScreenState createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final SongService _songService = SongService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    final songs = await _songService.fetchSongs();
    Provider.of<AudioProvider>(context, listen: false).setSongs(
      songs.map((song) => {
        'songUrl': song.url ?? '',
        'title': song.title,
        'artist': song.artist?.name ?? 'Unknown Artist',
        'imagePath': song.coverImage ?? 'default_image_url',
      }).toList(),
    );
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách bài hát")),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Consumer<AudioProvider>(
              builder: (context, audioProvider, child) {
                final songs = audioProvider.songs;
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      leading: Image.network(
                        song["imagePath"]!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note),
                      ),
                      title: Text(song["title"]!),
                      subtitle: Text(song["artist"]!),
                      onTap: () {
                        audioProvider.playSong(index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const MusicPlayer(),
        ],
      ),
    );
  }
}