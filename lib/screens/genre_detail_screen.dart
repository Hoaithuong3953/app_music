import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/genre.dart';
import '../providers/audio_provider.dart';

class GenreDetailScreen extends StatelessWidget {
  final Genre genre;

  const GenreDetailScreen({super.key, required this.genre});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    // Thiết lập danh sách bài hát cho AudioProvider
    final songsForProvider = (genre.songs ?? []).map((song) {
      return {
        'songUrl': song.url ?? '',
        'title': song.title,
        'artist': song.artist?.title ?? 'Unknown Artist',
        'imagePath': song.coverImage ?? 'default_image_url',
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(genre.title ?? 'Unknown Genre'),
        backgroundColor: Colors.grey[100],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh bìa thể loại
              if (genre.coverImage != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: genre.coverImage!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.album, size: 100),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Tiêu đề
              Text(
                genre.title ?? 'Unknown Genre',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              // Mô tả
              if (genre.description != null && genre.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  genre.description!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Nút phát tất cả
              if (genre.songs != null && genre.songs!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    audioProvider.setSongs(songsForProvider);
                    audioProvider.playSong(0); // Phát bài đầu tiên
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playing all songs in ${genre.title ?? 'Unknown Genre'}')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA6B9FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 16),

              // Danh sách bài hát
              Text(
                'Songs',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              genre.songs == null || genre.songs!.isEmpty
                  ? const Center(child: Text('No songs available'))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: genre.songs!.length,
                itemBuilder: (context, index) {
                  final song = genre.songs![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: song.coverImage != null
                          ? CachedNetworkImage(
                        imageUrl: song.coverImage!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.music_note, size: 50),
                      )
                          : const Icon(Icons.music_note, size: 50),
                      title: Text(song.title),
                      subtitle: Text(song.artist?.title ?? 'Unknown Artist'),
                      onTap: () {
                        audioProvider.setSongs(songsForProvider);
                        audioProvider.playSong(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playing: ${song.title}')),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}