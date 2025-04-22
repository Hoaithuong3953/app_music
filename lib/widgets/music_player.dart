import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/now_playing_screen.dart';
import '../providers/audio_provider.dart';

class MusicPlayer extends StatelessWidget {
  const MusicPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        // Kiểm tra bài hát hiện tại từ AudioProvider
        final currentIndex = audioProvider.currentIndex;
        final currentSong = currentIndex >= 0 && currentIndex < audioProvider.songs.length
            ? audioProvider.songs[currentIndex]
            : null;

        if (currentSong == null) {
          return const SizedBox();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFA6B9FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          currentSong['imagePath']?.isNotEmpty == true
                              ? currentSong['imagePath']!
                              : 'default_image_url',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.music_note),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong['title'] ?? 'Không xác định',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            currentSong['artist'] ?? 'Ca sĩ không xác định',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.black),
                        onPressed: audioProvider.playPrevious,
                      ),
                      IconButton(
                        icon: Icon(
                          audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                        ),
                        onPressed: audioProvider.togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.black),
                        onPressed: audioProvider.playNext,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}