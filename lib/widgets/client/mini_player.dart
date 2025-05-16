import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../pages/client/player_page.dart';

class MiniPlayer extends StatelessWidget {
  final Song song = Song(
    id: '1',
    title: 'Current Song',
    artist: 'artist_id_1', // ObjectId của nghệ sĩ
    album: 'album_id_1',  // ObjectId của album
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final String artistName = 'Artist'; // Tên nghệ sĩ (truyền từ ngoài hoặc lấy từ API)

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => PlayerPage(song: song),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = Offset(0.0, 1.0);
              var end = Offset.zero;
              var curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: ScaleTransition(
                  scale: animation.drive(Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: curve))),
                  child: child,
                ),
              );
            },
            transitionDuration: Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        height: 75,
        color: Theme.of(context).primaryColor, // Dùng primaryColor
        child: Padding(
          padding: EdgeInsets.all(8), // Thêm padding để tránh sát lề
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.secondary, // Dùng accentColor
                backgroundImage: song.coverImage != null ? NetworkImage(song.coverImage!) : null,
                child: song.coverImage == null
                    ? Text(
                  song.title.isNotEmpty ? song.title[0].toUpperCase() : 'S',
                  style: TextStyle(color: Theme.of(context).highlightColor),
                )
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      artistName, // Sử dụng tên nghệ sĩ truyền từ ngoài
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.play_arrow),
                color: Theme.of(context).colorScheme.secondary, // Dùng accentColor
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}