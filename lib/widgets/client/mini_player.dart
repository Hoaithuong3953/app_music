import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../pages/client/player_page.dart';
import '../../providers/song_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/audio_handler_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer2<SongProvider, PlaybackProvider>(
      builder: (context, songProvider, playbackProvider, child) {
        final currentSong = songProvider.currentSong;
        final isPlaying = playbackProvider.isPlaying;

        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        final hasValidUrl = currentSong.url != null && currentSong.url!.isNotEmpty;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => PlayerPage(song: currentSong),
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
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    backgroundImage: currentSong.coverImage != null ? NetworkImage(currentSong.coverImage!) : null,
                    child: currentSong.coverImage == null
                        ? Text(
                      currentSong.title.isNotEmpty ? currentSong.title[0].toUpperCase() : 'S',
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
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: screenWidth * 0.4, // Đảm bảo chiều rộng tối thiểu để scroll
                            ),
                            child: Text(
                              currentSong.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          hasValidUrl ? (currentSong.artist ?? 'Unknown Artist') : 'URL is missing',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasValidUrl ? Colors.grey[700] : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        onPressed: hasValidUrl
                            ? () {
                          songProvider.previousSong();
                          final newSong = songProvider.currentSong;
                          if (newSong != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Provider.of<AudioHandlerProvider>(context, listen: false).playSong(newSong);
                            });
                          }
                        }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        onPressed: hasValidUrl
                            ? () {
                          Provider.of<AudioHandlerProvider>(context, listen: false).playPause();
                        }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_next,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        onPressed: hasValidUrl
                            ? () {
                          songProvider.nextSong();
                          final newSong = songProvider.currentSong;
                          if (newSong != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Provider.of<AudioHandlerProvider>(context, listen: false).playSong(newSong);
                            });
                          }
                        }
                            : null,
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
  }
}