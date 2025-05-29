import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../providers/song_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/audio_handler_provider.dart';
import '../../service/client/song_service.dart';

class PlayerPage extends StatefulWidget {
  final Song? song;

  const PlayerPage({this.song, super.key});

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool isWishlisted = false;
  String? errorMessage;
  List<Map<String, dynamic>> songList = [];
  bool isLoadingSongs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSong();
      _fetchSongs();
    });
  }

  Future<void> _initSong() async {
    if (widget.song == null) return;

    try {
      final songProvider = Provider.of<SongProvider>(context, listen: false);
      final audioHandlerProvider = Provider.of<AudioHandlerProvider>(context, listen: false);

      if (songProvider.currentSong?.id != widget.song!.id) {
        songProvider.setCurrentSong(widget.song!);
        await audioHandlerProvider.playSong(widget.song!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading audio: $e';
      });
    }
  }

  Future<void> _fetchSongs() async {
    setState(() {
      isLoadingSongs = true;
      errorMessage = null;
    });

    try {
      final songService = SongService();
      final fetchedSongs = await songService.getAllSongs(limit: 10);
      setState(() {
        songList = fetchedSongs;
        isLoadingSongs = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading songs: $e';
        isLoadingSongs = false;
      });
    }
  }

  void toggleWishlist() {
    setState(() {
      isWishlisted = !isWishlisted;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer2<SongProvider, PlaybackProvider>(
      builder: (context, songProvider, playbackProvider, child) {
        final currentSong = songProvider.currentSong;
        final isPlaying = playbackProvider.isPlaying;

        return Consumer<AudioHandlerProvider>(
            builder: (context, audioHandlerProvider, child) {
              return Scaffold(
                body: Container(
                  color: Colors.white,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: screenHeight * 0.035,
                                  color: Theme.of(context).highlightColor,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                          Expanded(
                            flex: 9,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(height: screenHeight * 0.01),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: screenWidth * 0.75,
                                      height: screenWidth * 0.75,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: currentSong?.coverImage != null
                                          ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          currentSong!.coverImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Icon(
                                              Icons.music_note,
                                              size: screenWidth * 0.3,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      )
                                          : Center(
                                        child: Icon(
                                          Icons.music_note,
                                          size: screenWidth * 0.3,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: screenHeight * 0.045,
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                physics: const ClampingScrollPhysics(),
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    minWidth: screenWidth * 0.5,
                                                  ),
                                                  child: Text(
                                                    currentSong != null ? currentSong.title : 'No song playing',
                                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                                      fontSize: screenHeight * 0.035,
                                                      color: Theme.of(context).highlightColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: screenHeight * 0.005),
                                            SizedBox(
                                              height: screenHeight * 0.03,
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                physics: const ClampingScrollPhysics(),
                                                child: Text(
                                                  currentSong != null
                                                      ? (currentSong.artist ?? 'Unknown Artist')
                                                      : 'Select a song below',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontSize: screenHeight * 0.02,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (currentSong != null)
                                        IconButton(
                                          icon: Icon(
                                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                                            size: screenHeight * 0.035,
                                            color: isWishlisted ? Colors.red : Theme.of(context).highlightColor,
                                          ),
                                          onPressed: toggleWishlist,
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      if (errorMessage != null)
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                                          child: Text(
                                            errorMessage!,
                                            style: TextStyle(color: Colors.red, fontSize: screenHeight * 0.02),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      if (currentSong != null) ...[
                                        Slider(
                                          value: playbackProvider.position.inSeconds.toDouble(),
                                          min: 0,
                                          max: playbackProvider.duration.inSeconds.toDouble() > 0
                                              ? playbackProvider.duration.inSeconds.toDouble()
                                              : 1,
                                          activeColor: Theme.of(context).highlightColor,
                                          inactiveColor: Colors.grey[300],
                                          onChanged: (value) {
                                            audioHandlerProvider.seek(Duration(seconds: value.toInt()));
                                          },
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(playbackProvider.position),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontSize: screenHeight * 0.018,
                                              ),
                                            ),
                                            Text(
                                              currentSong.duration ?? _formatDuration(playbackProvider.duration),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontSize: screenHeight * 0.018,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.shuffle,
                                                size: screenHeight * 0.035,
                                                color: Theme.of(context).highlightColor,
                                              ),
                                              onPressed: () {},
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.skip_previous,
                                                size: screenHeight * 0.045,
                                                color: Theme.of(context).highlightColor,
                                              ),
                                              onPressed: currentSong.url != null && currentSong.url!.isNotEmpty
                                                  ? () {
                                                songProvider.previousSong();
                                                final newSong = songProvider.currentSong;
                                                if (newSong != null) {
                                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                                    audioHandlerProvider.playSong(newSong);
                                                  });
                                                }
                                              }
                                                  : null,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                playbackProvider.isPlaying
                                                    ? Icons.pause_circle_filled
                                                    : Icons.play_circle_filled,
                                                size: screenHeight * 0.07,
                                                color: Theme.of(context).highlightColor,
                                              ),
                                              onPressed: currentSong.url != null && currentSong.url!.isNotEmpty
                                                  ? () => audioHandlerProvider.playPause()
                                                  : null,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.skip_next,
                                                size: screenHeight * 0.045,
                                                color: Theme.of(context).highlightColor,
                                              ),
                                              onPressed: currentSong.url != null && currentSong.url!.isNotEmpty
                                                  ? () {
                                                songProvider.nextSong();
                                                final newSong = songProvider.currentSong;
                                                if (newSong != null) {
                                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                                    audioHandlerProvider.playSong(newSong);
                                                  });
                                                }
                                              }
                                                  : null,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.repeat,
                                                size: screenHeight * 0.035,
                                                color: Theme.of(context).highlightColor,
                                              ),
                                              onPressed: () {},
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        // Hiển thị danh sách bài hát để chọn
                                        Expanded(
                                          child: isLoadingSongs
                                              ? Center(child: CircularProgressIndicator())
                                              : errorMessage != null
                                              ? Center(child: Text(errorMessage!))
                                              : songList.isEmpty
                                              ? Center(child: Text('No songs available'))
                                              : ListView.builder(
                                            itemCount: songList.length,
                                            itemBuilder: (context, index) {
                                              final songData = songList[index];
                                              final song = songData['song'] as Song;
                                              final artistName = songData['artistName'] as String;
                                              return ListTile(
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: screenWidth * 0.02,
                                                  vertical: 0,
                                                ),
                                                leading: Container(
                                                  width: screenWidth * 0.12,
                                                  height: screenWidth * 0.12,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: song.coverImage != null
                                                      ? ClipOval(
                                                    child: Image.network(
                                                      song.coverImage!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Center(
                                                            child: Text(
                                                              song.title.isNotEmpty
                                                                  ? song.title[0].toUpperCase()
                                                                  : 'S',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: screenWidth * 0.04,
                                                              ),
                                                            ),
                                                          ),
                                                    ),
                                                  )
                                                      : Center(
                                                    child: Text(
                                                      song.title.isNotEmpty
                                                          ? song.title[0].toUpperCase()
                                                          : 'S',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: screenWidth * 0.04,
                                                      ),
                                                    ),
                                                  ),
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
                                                onTap: () {
                                                  // Cập nhật currentSong và phát bài hát
                                                  songProvider.setCurrentSong(song);
                                                  audioHandlerProvider.playSong(song);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
      },
    );
  }
}