import 'package:flutter/material.dart';
import '../managers/audio_player_manager.dart';

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
    final AudioPlayerManager _audioManager = AudioPlayerManager();

    return ValueListenableBuilder<Map<String, String>?>(
      valueListenable: _audioManager.currentSongData,
      builder: (context, currentSong, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _audioManager.isPlayingNotifier,
          builder: (context, isPlaying, child) {
            bool isCurrentPlaying = currentSong?["title"] == title && isPlaying;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imagePath.isNotEmpty ? imagePath : 'default_image_url',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          artist,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isCurrentPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: const Color(0xFFA6B9FF),
                      size: 32,
                    ),
                    onPressed: () {
                      _audioManager.play(songUrl, title, artist, imagePath);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
