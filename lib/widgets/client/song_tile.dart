import 'package:flutter/material.dart';
import '../../models/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final int index;
  final bool isRanking;
  final String artistName;

  const SongTile({
    required this.song,
    required this.index,
    required this.artistName,
    this.isRanking = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final avatarSize = screenWidth * 0.1;

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
        artistName, // Sử dụng tên nghệ sĩ truyền từ ngoài
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: screenHeight * 0.018,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.play_arrow,
          size: screenHeight * 0.03,
          color: Theme.of(context).highlightColor,
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/player', arguments: song);
        },
      ),
      onTap: () {
        Navigator.pushNamed(context, '/player', arguments: song);
      },
    );
  }
}