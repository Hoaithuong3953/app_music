import 'package:flutter/material.dart';
import '../../widgets/client/song_tile.dart';
import '../../models/song.dart';

class ChartPage extends StatelessWidget {
  final List<Map<String, dynamic>> songs = [
    {
      'song': Song(
        id: '1',
        title: 'Song 1',
        artist: 'artist_id_1',
        album: 'album_id_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'plays': 1250000,
      'artistName': 'Artist 1',
    },
    {
      'song': Song(
        id: '2',
        title: 'Song 2',
        artist: 'artist_id_2',
        album: 'album_id_2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'plays': 980000,
      'artistName': 'Artist 2',
    },
    {
      'song': Song(
        id: '3',
        title: 'Song 3',
        artist: 'artist_id_3',
        album: 'album_id_3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'plays': 750000,
      'artistName': 'Artist 3',
    },
    {
      'song': Song(
        id: '4',
        title: 'Song 4',
        artist: 'artist_id_4',
        album: 'album_id_4',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'plays': 600000,
      'artistName': 'Artist 4',
    },
    {
      'song': Song(
        id: '5',
        title: 'Song 5',
        artist: 'artist_id_5',
        album: 'album_id_5',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'plays': 500000,
      'artistName': 'Artist 5',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (songs.length < 3) {
      return const Center(
        child: Text('Not enough songs to display the chart.'),
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
                itemBuilder: (context, index) => SongTile(
                  song: songs[index + 3]['song'],
                  artistName: songs[index + 3]['artistName'],
                  index: index + 4,
                  isRanking: true,
                ),
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
    final Song song = songData['song'];
    final String artistName = songData['artistName'];
    final int plays = songData['plays'];

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