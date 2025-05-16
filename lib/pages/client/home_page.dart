import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../widgets/client/album_card.dart';
import '../../widgets/client/artist_card.dart';
import '../../widgets/client/song_tile.dart';
import '../../providers/user_provider.dart';

class HomePage extends StatelessWidget {
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
      'artistName': 'Artist 2',
    },
  ];
  final List<Map<String, dynamic>> albums = [
    {
      'album': Album(
        id: '1',
        title: 'Album 1',
        artist: 'artist_id_1',
        slugify: 'album-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'artistName': 'Artist 1',
    },
    {
      'album': Album(
        id: '2',
        title: 'Album 2',
        artist: 'artist_id_2',
        slugify: 'album-2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'artistName': 'Artist 2',
    },
  ];
  final List<Artist> artists = [
    Artist(
      id: '1',
      title: 'Artist 1',
      slugify: 'artist-1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Artist(
      id: '2',
      title: 'Artist 2',
      slugify: 'artist-2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.user?.firstName ?? 'User'; // Lấy firstName từ UserProvider

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.12),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.only(top: screenHeight * 0.03),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.04), // Căn trái thẳng hàng với nội dung bên dưới
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: screenHeight * 0.03,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: screenHeight * 0.03,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Text(
                    'Hi, $userName',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: screenHeight * 0.03,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.fromLTRB(screenWidth * 0.04, 0, screenWidth * 0.04, 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.015),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, albums...',
                    filled: true,
                    fillColor: Colors.grey[200],
                    prefixIcon: Icon(
                      Icons.search,
                      size: screenHeight * 0.03,
                      color: Theme.of(context).highlightColor,
                    ),
                  ),
                  onChanged: (value) {},
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  'Recently Played',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: screenHeight * 0.025,
                    color: Theme.of(context).highlightColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                ...songs.asMap().entries.map(
                      (entry) => SongTile(
                    song: entry.value['song'],
                    artistName: entry.value['artistName'],
                    index: entry.key + 1,
                  ),
                ).toList(),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  'Top Albums',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: screenHeight * 0.025,
                    color: Theme.of(context).highlightColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                SizedBox(
                  height: screenHeight * 0.25,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: albums.map(
                          (albumData) => AlbumCard(
                        album: albumData['album'],
                        artistName: albumData['artistName'],
                      ),
                    ).toList(),
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  'Artists',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: screenHeight * 0.025,
                    color: Theme.of(context).highlightColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                SizedBox(
                  height: screenHeight * 0.18,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: artists.map((artist) => ArtistCard(artist: artist)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}