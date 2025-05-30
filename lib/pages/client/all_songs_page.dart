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
  List<Song> songs = [];
  bool isLoading = true;
  String? errorMessage;
  int page = 1;
  final int limit = 20;
  bool isLoadingMore = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAllSongs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllSongs({bool loadMore = false}) async {
    if (isLoadingMore || (!hasMore && loadMore)) return;
    setState(() {
      if (loadMore) {
        isLoadingMore = true;
      } else {
        isLoading = true;
        errorMessage = null;
      }
    });

    try {
      final fetchedSongs = await _songService.getAllSongs(page: page, limit: limit);
      final newSongs = fetchedSongs.map((songData) => songData['song'] as Song).toList();
      setState(() {
        if (loadMore) {
          songs.addAll(newSongs);
        } else {
          songs = newSongs;
        }
        hasMore = newSongs.length == limit;
        if (hasMore) page++;
        isLoading = false;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && hasMore && !isLoadingMore) {
      _fetchAllSongs(loadMore: true);
    }
  }

  // Thêm hàm tiện ích để lấy tên nghệ sĩ an toàn
  String getArtistName(dynamic artist) {
    if (artist == null) return 'Unknown Artist';
    if (artist is String) return artist;
    if (artist is Map && artist['title'] != null) return artist['title'];
    try {
      return artist.title ?? 'Unknown Artist';
    } catch (_) {
      return 'Unknown Artist';
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
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollEndNotification) {
                      _onScroll();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: songs.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= songs.length) {
                        return Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final song = songs[index];
                      final artistName = getArtistName(song.artist);
                      return SongTile(
                        song: song,
                        artistName: artistName,
                        index: index + 1,
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}