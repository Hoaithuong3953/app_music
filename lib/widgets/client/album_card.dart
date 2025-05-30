import 'package:flutter/material.dart';
import '../../models/album.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final String? artistName;

  const AlbumCard({required this.album, this.artistName, super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final cardWidth = screenWidth * 0.35;
    final imageSize = cardWidth;
    final textHeight = screenHeight * 0.07; // Tăng chiều cao để chứa font lớn hơn
    final cardHeight = imageSize + textHeight + (screenHeight * 0.01);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Ảnh bìa album
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
            // Phần văn bản (tiêu đề và tên nghệ sĩ)
            SizedBox(
              height: textHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    album.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: screenHeight * 0.022, // Tăng kích thước font
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artistName ?? 'Unknown Artist',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: screenHeight * 0.018, // Tăng kích thước font
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}