import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // Để tạo số ngẫu nhiên cho shuffle

// Enum cho chế độ lặp lại, đặt ngoài class AudioProvider
enum RepeatMode {
  none, // Không lặp
  one,  // Lặp một bài
  all,  // Lặp toàn bộ danh sách
}

class AudioProvider with ChangeNotifier {
  static final AudioProvider _instance = AudioProvider._internal();
  factory AudioProvider() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentSongUrl;

  ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  ValueNotifier<Map<String, String>?> currentSongData = ValueNotifier<Map<String, String>?>(null);
  ValueNotifier<double> audioPosition = ValueNotifier<double>(0.0);
  ValueNotifier<double> totalTime = ValueNotifier<double>(0.0);

  List<Map<String, String>> _songs = [];
  int _currentIndex = -1;

  // Trạng thái cho shuffle và repeat
  bool _isShuffleEnabled = false; // Bật/tắt chế độ phát ngẫu nhiên
  RepeatMode _repeatMode = RepeatMode.none; // Chế độ lặp lại

  // Getter
  List<Map<String, String>> get songs => _songs;
  int get currentIndex => _currentIndex;
  bool get isShuffleEnabled => _isShuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;

  AudioProvider._internal() {
    _audioPlayer.onPositionChanged.listen((Duration p) {
      audioPosition.value = p.inSeconds.toDouble();
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((Duration d) {
      totalTime.value = d.inSeconds.toDouble();
      notifyListeners();
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      isPlayingNotifier.value = (state == PlayerState.playing);
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _handleSongCompletion();
    });
  }

  // Thiết lập danh sách bài hát
  void setSongs(List<Map<String, String>> songs) {
    _songs = songs;
    _currentIndex = -1;
    notifyListeners();
  }

  // Phát bài hát
  Future<void> play(String url, String title, String artist, String imagePath) async {
    try {
      if (_currentSongUrl == url && isPlayingNotifier.value) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        _currentSongUrl = url;
        currentSongData.value = {
          "songUrl": url,
          "title": title,
          "artist": artist,
          "imagePath": imagePath,
        };
      }
      notifyListeners();
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  // Phát bài hát theo index
  void playSong(int index) {
    if (index < 0 || index >= _songs.length) return;
    final song = _songs[index];
    play(
      song["songUrl"]!,
      song["title"]!,
      song["artist"]!,
      song["imagePath"]!,
    );
    _currentIndex = index;
    notifyListeners();
  }

  // Chuyển bài tiếp theo
  void playNext() {
    if (_isShuffleEnabled) {
      _playRandomSong();
    } else if (_currentIndex < _songs.length - 1) {
      playSong(_currentIndex + 1);
    } else if (_repeatMode == RepeatMode.all) {
      playSong(0); // Quay lại bài đầu tiên nếu lặp toàn bộ
    }
  }

  // Quay lại bài trước
  void playPrevious() {
    if (_isShuffleEnabled) {
      _playRandomSong();
    } else if (_currentIndex > 0) {
      playSong(_currentIndex - 1);
    } else if (_repeatMode == RepeatMode.all) {
      playSong(_songs.length - 1); // Quay lại bài cuối nếu lặp toàn bộ
    }
  }

  // Chuyển đổi play/pause
  Future<void> togglePlayPause() async {
    try {
      if (_currentSongUrl == null) return;

      if (isPlayingNotifier.value) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      notifyListeners();
    } catch (e) {
      print("Error toggling play/pause: $e");
    }
  }

  // Dừng phát
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSongUrl = null;
    currentSongData.value = null;
    _currentIndex = -1;
    notifyListeners();
  }

  // Tua đến vị trí
  void seekTo(double position) {
    _audioPlayer.seek(Duration(seconds: position.toInt()));
    notifyListeners();
  }

  // Bật/tắt chế độ shuffle
  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
    print("Shuffle mode: $_isShuffleEnabled");
  }

  // Chuyển đổi chế độ lặp lại
  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.none;
        break;
    }
    notifyListeners();
    print("Repeat mode: $_repeatMode");
  }

  // Phát bài ngẫu nhiên
  void _playRandomSong() {
    if (_songs.isEmpty) return;
    final random = Random();
    int nextIndex;
    do {
      nextIndex = random.nextInt(_songs.length);
    } while (nextIndex == _currentIndex && _songs.length > 1); // Tránh lặp lại bài hiện tại nếu có thể
    playSong(nextIndex);
  }

  // Xử lý khi bài hát kết thúc
  void _handleSongCompletion() {
    if (_repeatMode == RepeatMode.one) {
      playSong(_currentIndex); // Lặp lại bài hiện tại
    } else if (_repeatMode == RepeatMode.all && _currentIndex == _songs.length - 1) {
      playSong(0); // Quay lại bài đầu tiên nếu lặp toàn bộ
    } else if (_isShuffleEnabled) {
      _playRandomSong(); // Phát ngẫu nhiên nếu bật shuffle
    } else if (_currentIndex < _songs.length - 1) {
      playNext(); // Phát bài tiếp theo nếu không lặp
    } else {
      stop(); // Dừng nếu không có chế độ lặp
    }
  }
}