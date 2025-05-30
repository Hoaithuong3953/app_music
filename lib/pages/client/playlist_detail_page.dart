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
import 'package:flutter/foundation.dart' show kIsWeb;

// Custom Cache Manager
class CustomCacheManager extends CacheManager {
  static const key = 'customCacheKey';
  static final CustomCacheManager _instance = CustomCacheManager._();

  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ));

  @override
  Future<FileInfo?> getFileFromCache(String key, {bool ignoreMemCache = false}) async {
    try {
      print('Attempting to get file from cache: $key');
      final fileInfo = await super.getFileFromCache(key, ignoreMemCache: ignoreMemCache);
      if (fileInfo == null) {
        print('File not found in cache: $key');
        return null;
      }
      if (!await fileInfo.file.exists()) {
        print('Cached file does not exist: ${fileInfo.file.path}');
        await removeFile(key);
        return null;
      }
      print('Successfully retrieved file from cache: $key');
      return fileInfo;
    } catch (e) {
      print('Error getting file from cache: $e');
      return null;
    }
  }

  @override
  Future<FileInfo> downloadFile(String url,
      {Map<String, String>? authHeaders, bool force = false, String? key}) async {
    int retries = 3;
    Duration retryDelay = const Duration(seconds: 1);

    print('Attempting to download file: $url');
    while (retries > 0) {
      try {
        final fileInfo = await super.downloadFile(
          url,
          authHeaders: authHeaders,
          force: force,
          key: key,
        );
        if (!await fileInfo.file.exists()) {
          throw Exception('Downloaded file does not exist');
        }
        print('Successfully downloaded file: $url');
        return fileInfo;
      } catch (e) {
        retries--;
        if (retries == 0) {
          print('Failed to download file after 3 retries: $e');
          throw Exception('Failed to download file: $e');
        }
        print('Download failed, retrying... ($retries attempts left)');
        await Future.delayed(retryDelay);
        retryDelay *= 2;
      }
    }
    throw Exception('Failed to download file after 3 retries');
  }

  Future<void> removeFile(String key) async {
    try {
      await super.removeFile(key);
      print('Successfully removed file from cache: $key');
    } catch (e) {
      print('Error removing file from cache: $e');
    }
  }

  @override
  Future<void> emptyCache() async {
    try {
      await super.emptyCache();
      print('Successfully emptied cache');
    } catch (e) {
      print('Error emptying cache: $e');
    }
  }

  Future<String> getFilePath(String key) async {
    if (kIsWeb) {
      print('Running on Web, path_provider not supported');
      return '/tmp/$key';
    }
    try {
      final directory = await getTemporaryDirectory();
      return p.join(directory.path, key);
    } catch (e) {
      print('Error getting file path: $e');
      throw Exception('Failed to get file path: $e');
    }
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
    print('Initializing PlaylistDetailPage with playlistId: ${widget.playlistId}');
    if (widget.playlistId != null) {
      _fetchPlaylist();
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

      if (!mounted) return;
      setState(() {
        playlist = fetchedPlaylist.copyWith(songs: detailedSongs);
        isLoading = false;
        print('Playlist loaded with ${detailedSongs.length} songs');
      });
      _fetchRecommendedSongs();
    } catch (e) {
      if (!mounted) return;
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
    if (playlist == null) return;

    setState(() {
      isLoadingRecommendations = true;
    });

    try {
      final songs = await _songService.getAllSongs(limit: 10);
      final playlistSongIds = playlist!.songs.map((song) => song.id).toSet();
      final filteredSongs = songs.where((songData) {
        final song = songData['song'] as Song;
        return !playlistSongIds.contains(song.id);
      }).toList();

      if (!mounted) return;
      setState(() {
        recommendedSongs = filteredSongs;
        isLoadingRecommendations = false;
        print('Loaded ${filteredSongs.length} recommended songs');
      });
    } catch (e) {
      if (!mounted) return;
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

      if (!mounted) return;
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
    print('Building PlaylistDetailPage...');
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    print('Screen size: width=$screenWidth, height=$screenHeight');
    print('Playlist: ${playlist?.title ?? "null"}');
    print('Recommended songs count: ${recommendedSongs.length}');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Playlist Details',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 20,
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Ảnh bìa playlist
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 200,
                                    height: 200,
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
                                          onTap: playlist != null ? _pickImage : null,
                                          borderRadius: BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.edit,
                                              size: 24,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Tiêu đề playlist
                              Text(
                                playlist!.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 24),
                              // Danh sách bài hát trong playlist
                              if (playlist!.songs.isEmpty)
                                const Center(
                                  child: Text(
                                    'No songs in this playlist',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              else
                                Column(
                                  children: [
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
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              // Tiêu đề "Recommended Songs"
                              const Text(
                                'Recommended Songs',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              // Danh sách bài hát đề xuất
                              if (isLoadingRecommendations)
                                const Center(child: CircularProgressIndicator())
                              else if (recommendedSongs.isEmpty)
                                const Center(
                                  child: Text(
                                    'No recommended songs available',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: recommendedSongs.length,
                                  itemBuilder: (context, index) {
                                    final songData = recommendedSongs[index];
                                    final song = songData['song'] as Song;
                                    final artistName = songData['artistName'] as String;
                                    print('Song cover image URL: ${song.coverImage}');
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                        leading: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Image.asset(
                                            'images/default_cover.jpg',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        title: Text(
                                          song.title,
                                          style: const TextStyle(fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          artistName,
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.blueAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => _addSongToPlaylist(song.id),
                                              borderRadius: BorderRadius.circular(20),
                                              child: const Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 24,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}