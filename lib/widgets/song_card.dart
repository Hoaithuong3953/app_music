import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart'; // Import AudioProvider thay vì AudioPlayerManager

class SongCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String artist;
  final String songUrl;
  final int index; // Thêm index để xác định vị trí trong danh sách

  const SongCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.artist,
    required this.songUrl,
    required this.index, // Thêm tham số index
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    return ValueListenableBuilder<Map<String, String>?>(
      valueListenable: audioProvider.currentSongData, // Sử dụng từ AudioProvider
      builder: (context, currentSong, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: audioProvider.isPlayingNotifier, // Sử dụng từ AudioProvider
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
                      if (isCurrentPlaying) {
                        audioProvider.togglePlayPause(); // Tạm dừng nếu đang phát
                      } else {
                        audioProvider.playSong(index); // Phát bài hát theo index
                      }
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