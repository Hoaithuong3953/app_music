import 'package:flutter/foundation.dart';
import '../models/song.dart';

class SongProvider with ChangeNotifier {
  Song? _currentSong;
  List<Song> _playlist = [];
  int _currentIndex = -1;
  String? _currentPlaylistId;

  Song? get currentSong => _currentSong;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  String? get currentPlaylistId => _currentPlaylistId;

  void setCurrentSong(Song song) {
    _currentSong = song;
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    notifyListeners();
  }

  void setPlaylist(List<Song> playlist, {String? playlistId}) {
    _playlist = playlist;
    _currentPlaylistId = playlistId;
    if (_playlist.isNotEmpty && _currentIndex == -1) {
      _currentIndex = 0;
      _currentSong = _playlist[0];
    }
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      _currentSong = _playlist[index];
      notifyListeners();
    }
  }

  void nextSong() {
    if (_playlist.isEmpty) return;
    int nextIndex = (_currentIndex + 1) % _playlist.length;
    setCurrentIndex(nextIndex);
  }

  void previousSong() {
    if (_playlist.isEmpty) return;
    int prevIndex = (_currentIndex - 1) < 0 ? _playlist.length - 1 : _currentIndex - 1;
    setCurrentIndex(prevIndex);
  }

  void clear() {
    _currentSong = null;
    _playlist = [];
    _currentIndex = -1;
    _currentPlaylistId = null;
    notifyListeners();
  }
}