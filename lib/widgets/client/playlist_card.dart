import 'package:flutter/material.dart';
import '../../models/playlist.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final String ownerName; // Tên người tạo playlist
  final int songCount;    // Số lượng bài hát trong playlist

  const PlaylistCard({
    required this.playlist,
    required this.ownerName,
    required this.songCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final iconSize = screenWidth * 0.12;

    return Card(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      color: const Color(0xFFE0E0E0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: screenHeight * 0.08, // Giới hạn chiều cao của card
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.005,
          ),
          leading: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: playlist.coverImageURL != null
                ? Image.network(
              playlist.coverImageURL!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.playlist_play,
                  size: iconSize * 0.6,
                  color: Theme.of(context).highlightColor,
                ),
              ),
            )
                : Center(
              child: Icon(
                Icons.playlist_play,
                size: iconSize * 0.6,
                color: Theme.of(context).highlightColor,
              ),
            ),
          ),
          title: Text(
            playlist.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: screenHeight * 0.02,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Text(
            '$ownerName - $songCount songs',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: screenHeight * 0.018,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}