import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../widgets/client/album_card.dart';
import '../../widgets/client/artist_card.dart';
import '../../widgets/client/song_tile.dart';
import '../../providers/user_provider.dart';
import '../../service/client/song_service.dart';
import '../../service/client/album_service.dart';
import '../../service/client/artist_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SongService _songService = SongService();
  final AlbumService _albumService = AlbumService();
  final ArtistService _artistService = ArtistService();

  List<Map<String, dynamic>> songs = [];
  List<Map<String, dynamic>> albums = [];
  List<Artist> artists = [];

  bool isLoading = true;
  String? songsError;
  String? albumsError;
  String? artistsError;

  final List<Artist> staticArtists = [
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
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      songsError = null;
      albumsError = null;
      artistsError = null;
    });

    try {
      // Lấy danh sách bài hát
      try {
        final fetchedSongs = await _songService.getAllSongs(limit: 5);
        setState(() {
          songs = fetchedSongs.map((songData) {
            final song = songData['song'] as Song;
            final artistName = songData['artistName'] as String;
            return {
              'song': song,
              'artistName': artistName,
            };
          }).toList();
        });
      } catch (e) {
        print('Error fetching songs: $e');
        setState(() {
          songsError = e.toString();
        });
      }

      // Lấy danh sách album
      try {
        final fetchedAlbums = await _albumService.getAllAlbums(limit: 5);
        setState(() {
          albums = fetchedAlbums;
        });
      } catch (e) {
        print('Error fetching albums: $e');
        setState(() {
          albumsError = e.toString();
        });
      }

      // Lấy danh sách nghệ sĩ
      try {
        final fetchedArtists = await _artistService.getAllArtists(limit: 5);
        setState(() {
          artists = fetchedArtists;
        });
      } catch (e) {
        print('Error fetching artists: $e');
        setState(() {
          artistsError = e.toString();
          artists = staticArtists;
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        songsError ??= e.toString();
        albumsError ??= e.toString();
        artistsError ??= e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.user?.firstName ?? 'User';
    final avatarImgURL = userProvider.user?.avatarImgURL; // Lấy avatarImgURL

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Tạo danh sách bài hát từ songs để truyền vào SongTile
    final List<Song> songList = songs.map((songData) => songData['song'] as Song).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.12),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.only(top: screenHeight * 0.03),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: screenHeight * 0.03,
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage: avatarImgURL != null ? NetworkImage(avatarImgURL) : null, // Hiển thị ảnh từ avatarImgURL
                    child: avatarImgURL == null // Nếu không có avatarImgURL, hiển thị chữ cái đầu
                        ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: screenHeight * 0.03,
                        color: Colors.white,
                      ),
                    )
                        : null,
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
                  onTap: () {
                    Navigator.pushNamed(context, '/search');
                  },
                  onChanged: (value) {},
                ),
                SizedBox(height: screenHeight * 0.015),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recently Played',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: screenHeight * 0.025,
                        color: Theme.of(context).highlightColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/all-songs');
                      },
                      child: Text(
                        'View All',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: screenHeight * 0.018,
                          color: Theme.of(context).highlightColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                songsError != null
                    ? Center(child: Text('Error loading songs: $songsError'))
                    : songs.isEmpty
                    ? Center(child: Text('No songs available'))
                    : Column(
                  children: songs.asMap().entries.map(
                        (entry) {
                      final song = entry.value['song'] as Song;
                      final artistName = entry.value['artistName'] as String;
                      return SongTile(
                        song: song,
                        artistName: artistName,
                        index: entry.key + 1,
                        playlist: songList,
                        playlistId: 'homepage',
                      );
                    },
                  ).toList(),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  'Top Albums',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: screenHeight * 0.025,
                    color: Theme.of(context).highlightColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                albumsError != null
                    ? Center(child: Text('Error loading albums: $albumsError'))
                    : SizedBox(
                  height: screenHeight * 0.25,
                  child: albums.isEmpty
                      ? Center(child: Text('No albums available'))
                      : ListView(
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
                artistsError != null
                    ? Center(child: Text('Error loading artists: $artistsError'))
                    : SizedBox(
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