import 'package:flutter/material.dart';
import '../managers/audio_player_manager.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayerManager _audioManager = AudioPlayerManager();
  List<Map<String, String>> _songs = [];
  int _currentIndex = -1;
  bool _isPlaying = false;

  AudioPlayerManager get audioManager => _audioManager;
  List<Map<String, String>> get songs => _songs;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;

  // Cập nhật danh sách bài hát và quản lý chỉ số hiện tại
  void setSongs(List<Map<String, String>> songs) {
    final currentSong = _currentIndex >= 0 && _currentIndex < _songs.length
        ? _songs[_currentIndex]
        : null;
    _songs = songs;

    if (currentSong != null) {
      // Kiểm tra xem bài hát hiện tại có trong danh sách mới không
      _currentIndex = _songs.indexWhere((song) =>
      song['songUrl'] == currentSong['songUrl'] &&
          song['title'] == currentSong['title']);
      if (_currentIndex == -1) {
        // Bài hát hiện tại không còn trong danh sách, dừng phát
        _audioManager.stop();
        _isPlaying = false;
      }
    } else {
      _currentIndex = -1;
    }
    notifyListeners();
  }

  // Phát bài hát từ một Map (dùng trong HomeScreen và SongCard)
  void playSong(Map<String, String> song) {
    try {
      // Kiểm tra và cung cấp giá trị mặc định
      final songUrl = song['songUrl']?.isNotEmpty == true ? song['songUrl']! : null;
      final title = song['title']?.isNotEmpty == true ? song['title']! : 'Tiêu đề không xác định';
      final artist = song['artist']?.isNotEmpty == true ? song['artist']! : 'Ca sĩ không xác định';
      final imagePath = song['imagePath']?.isNotEmpty == true ? song['imagePath']! : 'default_image_url';

      if (songUrl == null) {
        print('Lỗi: URL bài hát không hợp lệ');
        return;
      }

      // Kiểm tra xem bài hát có trong danh sách không
      _currentIndex = _songs.indexWhere((s) => s['songUrl'] == songUrl);
      if (_currentIndex == -1) {
        // Thêm bài hát vào danh sách nếu chưa có
        _songs.add({
          'songUrl': songUrl,
          'title': title,
          'artist': artist,
          'imagePath': imagePath,
        });
        _currentIndex = _songs.length - 1;
      }

      // Phát bài hát
      _audioManager.play(songUrl, title, artist, imagePath);
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('Lỗi khi phát bài hát: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  // Phát bài hát theo chỉ số (tùy chọn, dùng nội bộ)
  void playSongByIndex(int index) {
    if (index < 0 || index >= _songs.length) return;
    playSong(_songs[index]);
  }

  // Phát bài hát tiếp theo
  void playNext() {
    if (_currentIndex < _songs.length - 1) {
      playSongByIndex(_currentIndex + 1);
    }
  }

  // Phát bài hát trước đó
  void playPrevious() {
    if (_currentIndex > 0) {
      playSongByIndex(_currentIndex - 1);
    }
  }

  // Tạm dừng phát
  void pause() {
    _audioManager.pause();
    _isPlaying = false;
    notifyListeners();
  }

  // Tiếp tục phát
  void resume() {
    _audioManager.resume();
    _isPlaying = true;
    notifyListeners();
  }

  // Dừng phát
  void stop() {
    _audioManager.stop();
    _isPlaying = false;
    _currentIndex = -1;
    notifyListeners();
  }

  // Chuyển đổi trạng thái phát/tạm dừng
  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else if (_currentIndex >= 0 && _currentIndex < _songs.length) {
      resume();
    }
  }

  // Giải phóng tài nguyên
  @override
  void dispose() {
    _audioManager.dispose();
    super.dispose();
  }
}