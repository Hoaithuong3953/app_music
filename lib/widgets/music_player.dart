import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/now_playing_screen.dart';
import '../providers/audio_provider.dart';

class MusicPlayer extends StatelessWidget {
  const MusicPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return ValueListenableBuilder<Map<String, String>?>(
      valueListenable: audioProvider.currentSongData,
      builder: (context, songData, child) {
        if (songData == null) return const SizedBox();

        return ValueListenableBuilder<bool>(
          valueListenable: audioProvider.isPlayingNotifier,
          builder: (context, isPlaying, child) {
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
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Giảm padding dọc
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6), // Giảm bo góc nhẹ
                            child: Image.network(
                              songData["imagePath"] ?? 'default_image_url',
                              width: 40, // Giảm từ 50 xuống 40
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.music_note,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10), // Giảm từ 12 xuống 10
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // Thu gọn chiều cao của Column
                            children: [
                              Text(
                                songData["title"] ?? "Unknown",
                                style: const TextStyle(
                                  fontSize: 14, // Giảm từ 16 xuống 14
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis, // Cắt ngắn nếu quá dài
                                maxLines: 1,
                              ),
                              Text(
                                songData["artist"] ?? "Unknown Artist",
                                style: const TextStyle(
                                  fontSize: 12, // Giảm từ 14 xuống 12
                                  color: Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous, color: Colors.black),
                            iconSize: 24, // Giảm từ mặc định xuống 24
                            padding: const EdgeInsets.all(4), // Giảm padding của IconButton
                            onPressed: audioProvider.playPrevious,
                          ),
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.black,
                            ),
                            iconSize: 28, // Giảm từ mặc định xuống 28
                            padding: const EdgeInsets.all(4),
                            onPressed: audioProvider.togglePlayPause,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, color: Colors.black),
                            iconSize: 24,
                            padding: const EdgeInsets.all(4),
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
      },
    );
  }
}