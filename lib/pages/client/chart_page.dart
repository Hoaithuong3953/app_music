import 'package:flutter/material.dart';
import '../../widgets/client/song_tile.dart';
import '../../models/song.dart';
import '../../service/client/song_service.dart';

class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final SongService _songService = SongService();
  List<Map<String, dynamic>> songs = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedSongs = await _songService.getAllSongs();
      if (fetchedSongs.isEmpty) {
        setState(() {
          errorMessage = 'No songs available';
          isLoading = false;
        });
        return;
      }

      // Sắp xếp bài hát theo createdAt giảm dần (mới nhất trước)
      fetchedSongs.sort((a, b) {
        final songA = a['song'] as Song;
        final songB = b['song'] as Song;
        return songB.createdAt.compareTo(songA.createdAt);
      });

      // Giả định số lần phát (plays) giảm dần từ bài mới nhất
      final plays = [1250000, 980000, 750000, 600000, 500000]; // Giá trị giả định
      setState(() {
        songs = fetchedSongs.asMap().entries.map((entry) {
          final index = entry.key;
          final songData = entry.value;
          final song = songData['song'] as Song;
          final artistName = songData['artistName'] as String;
          return {
            'song': song,
            'artistName': artistName,
            'plays': index < plays.length ? plays[index] : 500000 - index * 10000, // Giảm dần nếu vượt quá plays
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(child: Text('Error: $errorMessage')),
      );
    }

    if (songs.length < 3) {
      return const Scaffold(
        body: Center(
          child: Text('Not enough songs to display the chart.'),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.03, screenWidth * 0.04, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Charts',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: screenHeight * 0.035,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Top 3 Grid: Top 1 ở giữa và to hơn, Top 2 và 3 ở hai bên
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Top 2 (bên trái)
                  Expanded(
                    child: _buildTopSongCard(
                      context,
                      rank: 2,
                      songData: songs[1],
                      imageSize: screenWidth * 0.18,
                      fontSizeTitle: screenHeight * 0.018,
                      fontSizeArtist: screenHeight * 0.014,
                      fontSizePlays: screenHeight * 0.012,
                      screenWidth: screenWidth,
                    ),
                  ),
                  // Top 1 (ở giữa, to hơn)
                  Expanded(
                    child: _buildTopSongCard(
                      context,
                      rank: 1,
                      songData: songs[0],
                      imageSize: screenWidth * 0.32,
                      fontSizeTitle: screenHeight * 0.025,
                      fontSizeArtist: screenHeight * 0.018,
                      fontSizePlays: screenHeight * 0.014,
                      screenWidth: screenWidth,
                    ),
                  ),
                  // Top 3 (bên phải)
                  Expanded(
                    child: _buildTopSongCard(
                      context,
                      rank: 3,
                      songData: songs[2],
                      imageSize: screenWidth * 0.18,
                      fontSizeTitle: screenHeight * 0.018,
                      fontSizeArtist: screenHeight * 0.014,
                      fontSizePlays: screenHeight * 0.012,
                      screenWidth: screenWidth,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                'Top Songs This Week',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: screenHeight * 0.025,
                  color: Theme.of(context).highlightColor,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              // Danh sách bài hát từ vị trí 4 trở đi
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: songs.length - 3,
                itemBuilder: (context, index) {
                  final songData = songs[index + 3];
                  final song = songData['song'] as Song;
                  final artistName = songData['artistName'] as String;
                  return SongTile(
                    song: song,
                    artistName: artistName,
                    index: index + 4,
                    isRanking: true,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSongCard(
      BuildContext context, {
        required int rank,
        required Map<String, dynamic> songData,
        required double imageSize,
        required double fontSizeTitle,
        required double fontSizeArtist,
        required double fontSizePlays,
        required double screenWidth,
      }) {
    final Song song = songData['song'] as Song;
    final String artistName = songData['artistName'] as String;
    final int plays = songData['plays'] as int;

    return Column(
      children: [
        Container(
          width: screenWidth * 0.075,
          height: screenWidth * 0.075,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).highlightColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: imageSize * 0.05),
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: song.coverImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              song.coverImage!,
              fit: BoxFit.cover,
              width: imageSize,
              height: imageSize,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.music_note,
                size: imageSize * 0.5,
                color: Colors.grey[600],
              ),
            ),
          )
              : Center(
            child: Icon(
              Icons.music_note,
              size: imageSize * 0.5,
              color: Colors.grey[600],
            ),
          ),
        ),
        SizedBox(height: imageSize * 0.1),
        Text(
          song.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: fontSizeTitle,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          artistName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: fontSizeArtist,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: imageSize * 0.05),
        Text(
          '${(plays / 1000).toStringAsFixed(1)}K plays',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: fontSizePlays,
            color: Theme.of(context).highlightColor,
          ),
        ),
      ],
    );
  }
}