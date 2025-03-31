import 'package:flutter/material.dart';
import '../managers/audio_player_manager.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayerManager _audioManager = AudioPlayerManager();
  List<Map<String, String>> _songs = [];
  int _currentIndex = -1;

  AudioPlayerManager get audioManager => _audioManager;
  List<Map<String, String>> get songs => _songs;
  int get currentIndex => _currentIndex;

  void setSongs(List<Map<String, String>> songs) {
    _songs = songs;
    _currentIndex = -1; // Reset index khi danh sách thay đổi
    notifyListeners();
  }

  void playSong(int index) {
    if (index < 0 || index >= _songs.length) return;
    final song = _songs[index];
    _audioManager.play(
      song["songUrl"]!,
      song["title"]!,
      song["artist"]!,
      song["imagePath"]!,
    );
    _currentIndex = index;
    notifyListeners();
  }

  void playNext() {
    if (_currentIndex < _songs.length - 1) {
      playSong(_currentIndex + 1);
    }
  }

  void playPrevious() {
    if (_currentIndex > 0) {
      playSong(_currentIndex - 1);
    }
  }
}