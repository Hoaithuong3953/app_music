import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../service/client/playlist_service.dart';
import '../../service/client/song_service.dart';
import '../../widgets/client/song_tile.dart';

class PlaylistDetailPage extends StatefulWidget {
  @override
  _PlaylistDetailPageState createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final PlaylistService _playlistService = PlaylistService();
  final SongService _songService = SongService();
  Playlist? playlist;
  List<Map<String, dynamic>> recommendedSongs = [];
  bool isLoading = true;
  bool isLoadingRecommendations = true;
  String? errorMessage;
  String? playlistId;
  File? _selectedImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (playlistId == null) {
      final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        playlistId = arguments['playlistId'] as String?;
        if (playlistId != null) {
          _fetchPlaylist();
          _fetchRecommendedSongs();
        } else {
          setState(() {
            errorMessage = 'Playlist ID not provided';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Invalid navigation arguments';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPlaylist() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedPlaylist = await _playlistService.getPlaylist(playlistId!);
      setState(() {
        playlist = fetchedPlaylist;
        isLoading = false;
      });
      _fetchRecommendedSongs();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _fetchRecommendedSongs() async {
    setState(() {
      isLoadingRecommendations = true;
    });

    try {
      final songs = await _songService.getAllSongs(limit: 10);
      final playlistSongIds = playlist?.songs.map((song) => song.id).toSet() ?? {};
      final filteredSongs = songs.where((songData) {
        final song = songData['song'] as Song;
        return !playlistSongIds.contains(song.id);
      }).toList();

      setState(() {
        recommendedSongs = filteredSongs;
        isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        isLoadingRecommendations = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recommended songs: $e')),
      );
    }
  }

  Future<void> _addSongToPlaylist(String songId) async {
    try {
      await _playlistService.addSongsToPlaylist(
        playlistId: playlistId!,
        songIds: [songId],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Song added to playlist')),
      );
      await _fetchPlaylist();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding song to playlist: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      try {
        await _playlistService.updatePlaylist(
          playlistId: playlistId!,
          coverImagePath: _selectedImage!.path,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playlist cover image updated successfully')),
        );
        await _fetchPlaylist();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating playlist cover image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.04, 0, screenWidth * 0.04, 0),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text('Error: $errorMessage'))
                : playlist == null
                ? Center(child: Text('Playlist not found'))
                : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      if (playlist!.coverImageURL != null &&
                          playlist!.coverImageURL != 'https://example.com/default-cover.jpg')
                        Container(
                          width: screenWidth * 0.5,
                          height: screenWidth * 0.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              playlist!.coverImageURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'images/default_cover.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: screenWidth * 0.5,
                          height: screenWidth * 0.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'images/default_cover.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).highlightColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              size: screenWidth * 0.06,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    playlist!.title,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: screenHeight * 0.03,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  playlist!.songs.isEmpty
                      ? Center(child: Text('No songs in this playlist'))
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: playlist!.songs.length,
                    itemBuilder: (context, index) {
                      final song = playlist!.songs[index];
                      return SongTile(
                        song: song,
                        artistName: song.artist ?? 'Unknown Artist',
                        index: index + 1,
                        isRanking: false,
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Recommended Songs',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: screenHeight * 0.025,
                      color: Theme.of(context).highlightColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  isLoadingRecommendations
                      ? Center(child: CircularProgressIndicator())
                      : recommendedSongs.isEmpty
                      ? Center(child: Text('No recommended songs available'))
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: recommendedSongs.length,
                    itemBuilder: (context, index) {
                      final songData = recommendedSongs[index];
                      final song = songData['song'] as Song;
                      final artistName = songData['artistName'] as String;
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.005,
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
                        trailing: IconButton(
                          icon: Icon(
                            Icons.add,
                            size: screenHeight * 0.03,
                            color: Theme.of(context).highlightColor,
                          ),
                          onPressed: () {
                            _addSongToPlaylist(song.id);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}