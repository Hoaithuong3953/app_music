import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart'; // Chỉ cần import AudioProvider

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  String _formatTime(double seconds) {
    int min = (seconds ~/ 60);
    int sec = (seconds % 60).toInt();
    return "$min:${sec.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFA6B9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ValueListenableBuilder<Map<String, String>?>(
        valueListenable: audioProvider.currentSongData, // Truy cập trực tiếp từ audioProvider
        builder: (context, songData, child) {
          if (songData == null) {
            return const Center(child: Text("Không có bài hát nào đang phát"));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    songData["imagePath"] ?? 'default_image_url',
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width - 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  songData["title"] ?? "Unknown",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  songData["artist"] ?? "Unknown Artist",
                  style: const TextStyle(fontSize: 18, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<double>(
                  valueListenable: audioProvider.audioPosition, // Truy cập trực tiếp
                  builder: (context, position, child) {
                    return ValueListenableBuilder<double>(
                      valueListenable: audioProvider.totalTime, // Truy cập trực tiếp
                      builder: (context, totalTime, child) {
                        return Column(
                          children: [
                            Slider(
                              value: position,
                              min: 0,
                              max: totalTime > 0 ? totalTime : 1,
                              activeColor: const Color(0xFFA6B9FF),
                              onChanged: audioProvider.seekTo, // Gọi trực tiếp từ audioProvider
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatTime(position), style: const TextStyle(color: Colors.black54)),
                                Text(_formatTime(totalTime), style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: audioProvider.isPlayingNotifier, // Truy cập trực tiếp
                  builder: (context, isPlaying, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 40, color: Color(0xFFA6B9FF)),
                          onPressed: audioProvider.playPrevious, // Gọi từ audioProvider
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            size: 60,
                            color: const Color(0xFFA6B9FF),
                          ),
                          onPressed: audioProvider.togglePlayPause, // Gọi từ audioProvider
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 40, color: Color(0xFFA6B9FF)),
                          onPressed: audioProvider.playNext, // Gọi từ audioProvider
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}