import 'package:flutter/material.dart';
import '../../models/album.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final String? artistName; // Thêm thuộc tính để truyền tên nghệ sĩ từ bên ngoài

  const AlbumCard({required this.album, this.artistName, super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final cardWidth = screenWidth * 0.35;
    final imageSize = cardWidth;
    final textHeight = screenHeight * 0.05;
    final cardHeight = imageSize + textHeight + (screenHeight * 0.01);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                width: imageSize,
                height: imageSize,
                color: Colors.grey[300],
                child: album.coverImageURL != null
                    ? Image.network(
                  album.coverImageURL!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.album,
                    size: imageSize * 0.5,
                    color: Theme.of(context).highlightColor,
                  ),
                )
                    : Icon(
                  Icons.album,
                  size: imageSize * 0.5,
                  color: Theme.of(context).highlightColor,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              album.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: screenHeight * 0.02,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              artistName ?? 'Unknown Artist', // Sử dụng artistName truyền từ ngoài
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: screenHeight * 0.018,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}