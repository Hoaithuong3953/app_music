import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../providers/song_provider.dart';
import '../../providers/audio_handler_provider.dart';
import '../../providers/playback_provider.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final int index;
  final bool isRanking;
  final String artistName;
  final List<Song>? playlist;
  final String? playlistId;
  final VoidCallback? onTap;

  const SongTile({
    required this.song,
    required this.index,
    required this.artistName,
    this.isRanking = false,
    this.playlist,
    this.playlistId,
    this.onTap,
    super.key,
  });

  Future<void> _playSong(BuildContext context) async {
    try {
      if (song.url == null || song.url!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot play song: URL is missing')),
        );
        return;
      }

      final songProvider = Provider.of<SongProvider>(context, listen: false);
      final audioHandlerProvider = Provider.of<AudioHandlerProvider>(context, listen: false);
      final playbackProvider = Provider.of<PlaybackProvider>(context, listen: false);

      if (playlist != null) {
        songProvider.setPlaylist(playlist!, playlistId: playlistId ?? 'homepage');
      } else {
        songProvider.setPlaylist([song], playlistId: 'single_song_${song.id}');
      }

      songProvider.setCurrentSong(song);

      if (songProvider.currentSong?.id == song.id && playbackProvider.isPlaying) {
        await audioHandlerProvider.playPause();
      } else {
        await audioHandlerProvider.playSong(song);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing song: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final avatarSize = screenWidth * 0.1;

    return Consumer2<SongProvider, PlaybackProvider>(
      builder: (context, songProvider, playbackProvider, child) {
        final isCurrentSong = songProvider.currentSong?.id == song.id;
        final isPlaying = playbackProvider.isPlaying;

        return ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: screenWidth * 0.06,
                child: Text(
                  '$index',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: isRanking ? screenHeight * 0.025 : screenHeight * 0.02,
                        color: isRanking ? Colors.grey[800] : Colors.grey[600],
                        fontWeight: isRanking ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: song.coverImage != null
                    ? ClipOval(
                        child: Image.network(
                          song.coverImage!,
                          fit: BoxFit.cover,
                          width: avatarSize,
                          height: avatarSize,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              song.title.isNotEmpty ? song.title[0].toUpperCase() : 'S',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: avatarSize * 0.4,
                                  ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          song.title.isNotEmpty ? song.title[0].toUpperCase() : 'S',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontSize: avatarSize * 0.4,
                              ),
                        ),
                      ),
              ),
            ],
          ),
          title: Text(
            song.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: screenHeight * 0.02,
                ),
          ),
          subtitle: Text(
            artistName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: screenHeight * 0.018,
                ),
          ),
          trailing: IconButton(
            icon: Icon(
              isCurrentSong && isPlaying ? Icons.pause : Icons.play_arrow,
              size: screenHeight * 0.03,
              color: Theme.of(context).highlightColor,
            ),
            onPressed: () => _playSong(context),
          ),
          onTap: onTap, // Ưu tiên onTap tùy chỉnh, không dùng _playSong nếu onTap được cung cấp
        );
      },
    );
  }
}