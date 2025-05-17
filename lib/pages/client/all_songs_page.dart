import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../service/client/song_service.dart';
import '../../widgets/client/song_tile.dart';

class AllSongsPage extends StatefulWidget {
  @override
  _AllSongsPageState createState() => _AllSongsPageState();
}

class _AllSongsPageState extends State<AllSongsPage> {
  final SongService _songService = SongService();
  List<Map<String, dynamic>> songs = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllSongs();
  }

  Future<void> _fetchAllSongs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedSongs = await _songService.getAllSongs(); // Lấy tất cả bài hát, không giới hạn
      setState(() {
        songs = fetchedSongs.map((songData) {
          final song = songData['song'] as Song; // Ép kiểu rõ ràng
          final artistName = songData['artistName'] as String;
          return {
            'song': song,
            'artistName': artistName,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Songs',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: screenHeight * 0.025,
            color: Colors.black,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.fromLTRB(screenWidth * 0.04, 0, screenWidth * 0.04, 0),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : songs.isEmpty
              ? Center(child: Text('No songs available'))
              : ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final entry = songs[index];
              final song = entry['song'] as Song;
              final artistName = entry['artistName'] as String;
              return SongTile(
                song: song,
                artistName: artistName,
                index: index + 1,
              );
            },
          ),
        ),
      ),
    );
  }
}