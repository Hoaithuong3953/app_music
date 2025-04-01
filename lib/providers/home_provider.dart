import 'package:flutter/material.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/user.dart';
import '../service/song_service.dart';
import '../service/user_service.dart';
import '../service/album_service.dart';

class HomeProvider extends ChangeNotifier {
  String _username = "Loading...";
  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _isLoading = true;

  String get username => _username;
  List<Song> get songs => _songs;
  List<Album> get albums => _albums;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    try {
      const String baseUrl = "http://10.0.2.2:8080";
      final userService = UserService(baseUrl: baseUrl);
      final songService = SongService();
      final albumService = AlbumService();

      final results = await Future.wait([
        userService.getCurrentUser(),
        songService.fetchSongs(),
        albumService.fetchAlbums(),
      ]);

      _username = (results[0] as User).firstName;
      _songs = results[1] as List<Song>;
      _albums = results[2] as List<Album>;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      _username = "User";
      _isLoading = false;
      notifyListeners();
    }
  }
}
