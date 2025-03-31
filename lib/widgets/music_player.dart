import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/now_playing_screen.dart';
import '../providers/audio_provider.dart';

class MusicPlayer extends StatelessWidget {
  const MusicPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final audioManager = audioProvider.audioManager;

    return ValueListenableBuilder<Map<String, String>?>(
      valueListenable: audioManager.currentSongData,
      builder: (context, songData, child) {
        if (songData == null) return const SizedBox();

        return ValueListenableBuilder<bool>(
          valueListenable: audioManager.isPlayingNotifier,
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
                              songData["imagePath"] ?? 'default_image_url',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                songData["title"] ?? "Unknown",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                songData["artist"] ?? "Unknown Artist",
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
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.black,
                            ),
                            onPressed: audioManager.togglePlayPause,
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
      },
    );
  }
}