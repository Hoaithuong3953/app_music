import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../screens/now_playing_screen.dart';

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
    final audioProvider = Provider.of<AudioProvider>(context);

    // Kiểm tra xem bài hát này có đang phát không
    final isCurrentSong = audioProvider.currentIndex >= 0 &&
        audioProvider.songs[audioProvider.currentIndex]['songUrl'] == songUrl;

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
        label: 'play_song_button',
        child: IconButton(
          icon: Icon(
            isCurrentSong && audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
            color: const Color(0xFFA6B9FF),
          ),
          onPressed: () {
            if (isCurrentSong && audioProvider.isPlaying) {
              audioProvider.pause();
            } else {
              // Tìm index của bài hát trong danh sách
              final index = audioProvider.songs
                  .indexWhere((song) => song['songUrl'] == songUrl);
              if (index >= 0) {
                audioProvider.playSongByIndex(index);
              } else {
                // Nếu bài hát không có trong danh sách, thêm và phát
                audioProvider.playSong({
                  'songUrl': songUrl,
                  'title': title,
                  'artist': artist,
                  'imagePath': imagePath,
                });
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
              );
            }
          },
        ),
      ),
      onTap: () {
        // Tương tự logic của nút phát
        final index = audioProvider.songs
            .indexWhere((song) => song['songUrl'] == songUrl);
        if (index >= 0) {
          audioProvider.playSongByIndex(index);
        } else {
          audioProvider.playSong({
            'songUrl': songUrl,
            'title': title,
            'artist': artist,
            'imagePath': imagePath,
          });
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
        );
      },
    );
  }
}