import 'package:flutter/material.dart';
import '../../service/client/album_service.dart';
import '../../service/client/song_service.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../widgets/client/song_tile.dart';

class AlbumDetailPage extends StatefulWidget {
  final String albumId;
  const AlbumDetailPage({Key? key, required this.albumId}) : super(key: key);

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final AlbumService _albumService = AlbumService();
  final SongService _songService = SongService();
  Album? album;
  String artistName = '';
  List<Song> songs = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAlbumDetail();
  }

  Future<void> _fetchAlbumDetail() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final albumData = await _albumService.getAlbumById(widget.albumId);
      final Album fetchedAlbum = albumData['album'] as Album;
      final String fetchedArtist = albumData['artistName'] as String;
      List<Song> fetchedSongs = [];
      if (fetchedAlbum.songs.isNotEmpty) {
        fetchedSongs = await _songService.getSongsByIds(fetchedAlbum.songs);
      }
      setState(() {
        album = fetchedAlbum;
        artistName = fetchedArtist;
        songs = fetchedSongs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String getArtistName(dynamic artist) {
    if (artist == null) return 'Unknown Artist';
    if (artist is Map && artist['title'] != null) return artist['title'].toString();
    if (artist is String) return artist;
    return 'Unknown Artist';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Album Detail'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : album == null
                  ? Center(child: Text('Album not found'))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: screenHeight * 0.02),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: album!.coverImageURL != null && album!.coverImageURL!.isNotEmpty
                                  ? Image.network(
                                      album!.coverImageURL!,
                                      width: screenWidth * 0.6,
                                      height: screenWidth * 0.6,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: screenWidth * 0.6,
                                      height: screenWidth * 0.6,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.album, size: screenWidth * 0.2, color: Colors.grey),
                                    ),
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            Text(
                              album!.title,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontSize: screenHeight * 0.032,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              artistName,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: screenHeight * 0.022,
                                    color: Theme.of(context).highlightColor,
                                  ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Số bài hát: ${songs.length}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: screenHeight * 0.018,
                                  ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Ngày tạo: ${album!.createdAt.toLocal().toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: screenHeight * 0.018,
                                  ),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Danh sách bài hát',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontSize: screenHeight * 0.025,
                                      color: Theme.of(context).highlightColor,
                                    ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            songs.isEmpty
                                ? Center(child: Text('Không có bài hát nào trong album này'))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: songs.length,
                                    separatorBuilder: (_, __) => Divider(),
                                    itemBuilder: (context, index) {
                                      final song = songs[index];
                                      return SongTile(
                                        song: song,
                                        artistName: getArtistName(song.artist),
                                        index: index + 1,
                                      );
                                    },
                                  ),
                            SizedBox(height: screenHeight * 0.03),
                          ],
                        ),
                      ),
                    ),
    );
  }
} 