import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../service/client/playlist_service.dart';
import '../../service/client/song_service.dart';
import '../../widgets/client/song_tile.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Tạo custom cache manager với retry mechanism
class CustomCacheManager extends CacheManager {
  static const key = 'customCacheKey';
  static final CustomCacheManager _instance = CustomCacheManager._();
  
  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 100,
    repo: JsonCacheInfoRepository(databaseName: key),
    fileService: HttpFileService(),
  ));

  @override
  Future<FileInfo?> getFileFromCache(String key, {bool ignoreMemCache = false}) async {
    try {
      final fileInfo = await super.getFileFromCache(key, ignoreMemCache: ignoreMemCache);
      if (fileInfo == null) {
        print('File not found in cache: $key');
        return null;
      }
      
      // Verify file exists
      if (!await fileInfo.file.exists()) {
        print('Cached file does not exist: ${fileInfo.file.path}');
        await removeFile(key);
        return null;
      }
      
      return fileInfo;
    } catch (e) {
      print('Error getting file from cache: $e');
      return null;
    }
  }

  @override
  Future<FileInfo> downloadFile(String url, {
    Map<String, String>? authHeaders,
    bool force = false,
    String? key,
  }) async {
    int retries = 3;
    Duration retryDelay = const Duration(seconds: 1);
    
    while (retries > 0) {
      try {
        final fileInfo = await super.downloadFile(
          url,
          authHeaders: authHeaders,
          force: force,
          key: key,
        );
        
        // Verify downloaded file
        if (!await fileInfo.file.exists()) {
          throw Exception('Downloaded file does not exist');
        }
        
        return fileInfo;
      } catch (e) {
        retries--;
        if (retries == 0) {
          print('Failed to download file after 3 retries: $e');
          rethrow;
        }
        print('Download failed, retrying... ($retries attempts left)');
        await Future.delayed(retryDelay);
        // Increase delay for next retry
        retryDelay *= 2;
      }
    }
    throw Exception('Failed to download file after 3 retries');
  }

  Future<void> removeFile(String key) async {
    try {
      await super.removeFile(key);
    } catch (e) {
      print('Error removing file from cache: $e');
    }
  }

  @override
  Future<void> emptyCache() async {
    try {
      await super.emptyCache();
    } catch (e) {
      print('Error emptying cache: $e');
    }
  }

  Future<String> getFilePath(String key) async {
    final directory = await getTemporaryDirectory();
    return p.join(directory.path, key);
  }

  Future<bool> isFileCached(String key) async {
    try {
      final fileInfo = await getFileFromCache(key);
      return fileInfo != null && await fileInfo.file.exists();
    } catch (e) {
      print('Error checking if file is cached: $e');
      return false;
    }
  }
}

class PlaylistDetailPage extends StatefulWidget {
  final String? playlistId;

  const PlaylistDetailPage({Key? key, this.playlistId}) : super(key: key);

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
  File? _selectedImage;
  final CustomCacheManager _cacheManager = CustomCacheManager();

  @override
  void initState() {
    super.initState();
    if (widget.playlistId != null) {
      _fetchPlaylist();
      _fetchRecommendedSongs();
    } else {
      setState(() {
        errorMessage = 'Playlist ID not provided';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchPlaylist() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedPlaylist = await _playlistService.getPlaylist(widget.playlistId!);
      print('Fetched playlist: ${fetchedPlaylist.toJson()}');

      // Lấy thông tin chi tiết của từng bài hát trong playlist
      List<Song> detailedSongs = [];
      for (var song in fetchedPlaylist.songs) {
        try {
          final detailedSong = await _songService.getSong(song.id);
          detailedSongs.add(detailedSong);
        } catch (e) {
          print('Error fetching song ${song.id}: $e');
          detailedSongs.add(Song(
            id: song.id,
            title: 'Unknown Song',
            description: null,
            lyrics: null,
            artist: null,
            album: null,
            genre: const [],
            duration: null,
            slugify: null,
            url: null,
            coverImage: null,
            views: 0,
            dailyViews: 0,
            weeklyViews: 0,
            trendingScore: 0,
            lastReset: DateTime.now(),
            likes: const [],
            dislikes: const [],
            comments: const [],
            isPublic: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      setState(() {
        playlist = fetchedPlaylist.copyWith(songs: detailedSongs);
        isLoading = false;
      });
      _fetchRecommendedSongs();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading playlist: $e')),
      );
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
      final updatedPlaylist = await _playlistService.addSongsToPlaylist(
        playlistId: widget.playlistId!,
        songIds: [songId],
      );
      print('Updated playlist after adding song: ${updatedPlaylist.toJson()}');

      // Lấy thông tin chi tiết của từng bài hát trong playlist sau khi thêm
      List<Song> detailedSongs = [];
      for (var song in updatedPlaylist.songs) {
        try {
          final detailedSong = await _songService.getSong(song.id);
          detailedSongs.add(detailedSong);
        } catch (e) {
          print('Error fetching song ${song.id}: $e');
          detailedSongs.add(Song(
            id: song.id,
            title: 'Unknown Song',
            description: null,
            lyrics: null,
            artist: null,
            album: null,
            genre: const [],
            duration: null,
            slugify: null,
            url: null,
            coverImage: null,
            views: 0,
            dailyViews: 0,
            weeklyViews: 0,
            trendingScore: 0,
            lastReset: DateTime.now(),
            likes: const [],
            dislikes: const [],
            comments: const [],
            isPublic: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      setState(() {
        playlist = updatedPlaylist.copyWith(songs: detailedSongs);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Song added to playlist')),
      );
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
          playlistId: widget.playlistId!,
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
        title: Text(
          'Playlist Details',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: screenHeight * 0.025,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : playlist == null
                  ? const Center(child: Text('Playlist not found'))
                  : SafeArea(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
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
                                        child: CachedNetworkImage(
                                          cacheManager: _cacheManager,
                                          imageUrl: playlist!.coverImageURL!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) {
                                            print('Error loading playlist image: $error');
                                            return Container(
                                              color: Colors.grey[300],
                                              child: Center(
                                                child: Icon(
                                                  Icons.music_note,
                                                  size: screenWidth * 0.2,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            );
                                          },
                                          maxWidthDiskCache: 500,
                                          maxHeightDiskCache: 500,
                                          memCacheWidth: 500,
                                          memCacheHeight: 500,
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
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).highlightColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _pickImage,
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.edit,
                                              size: screenWidth * 0.06,
                                              color: Colors.white,
                                            ),
                                          ),
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
                              if (playlist!.songs.isEmpty)
                                const Center(child: Text('No songs in this playlist'))
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: playlist!.songs.length,
                                  itemBuilder: (context, index) {
                                    final song = playlist!.songs[index];
                                    return SongTile(
                                      song: song,
                                      artistName: song.artist ?? 'Unknown Artist',
                                      index: index + 1,
                                      isRanking: false,
                                      playlist: List<Song>.from(playlist!.songs),
                                      playlistId: playlist!.id,
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
                              if (isLoadingRecommendations)
                                const Center(child: CircularProgressIndicator())
                              else if (recommendedSongs.isEmpty)
                                const Center(child: Text('No recommended songs available'))
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
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
                                                child: CachedNetworkImage(
                                                  cacheManager: _cacheManager,
                                                  imageUrl: song.coverImage!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child: CircularProgressIndicator(),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) {
                                                    print('Error loading song image: $error');
                                                    return Center(
                                                      child: Text(
                                                        song.title.isNotEmpty
                                                            ? song.title[0].toUpperCase()
                                                            : 'S',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: screenWidth * 0.04,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  maxWidthDiskCache: 200,
                                                  maxHeightDiskCache: 200,
                                                  memCacheWidth: 200,
                                                  memCacheHeight: 200,
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
                                      trailing: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).highlightColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _addSongToPlaylist(song.id),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.add,
                                                size: screenHeight * 0.03,
                                                color: Theme.of(context).highlightColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              SizedBox(height: screenHeight * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}