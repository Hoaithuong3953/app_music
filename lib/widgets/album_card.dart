import 'package:flutter/material.dart';

class AlbumCard extends StatelessWidget {
  final String imagePath;
  final String title;

  const AlbumCard({
    Key? key,
    required this.imagePath,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 200, // Giảm chiều cao tổng thể để gọn gàng hơn
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: () {
          // Có thể thêm hành động khi nhấn vào card (ví dụ: mở chi tiết album)
        },
        child: Stack(
          children: [
            // Container chính với ảnh bìa
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imagePath,
                width: 160,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 160,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.album, size: 60, color: Colors.grey),
                ),
              ),
            ),
            // Gradient overlay để làm nổi bật tiêu đề
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            // Tiêu đề album
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18, // Tăng kích thước chữ
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Chữ trắng để nổi trên gradient
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ),
            // Hiệu ứng viền khi hover (tùy chọn)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {},
                  splashColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}