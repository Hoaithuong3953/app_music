import 'package:flutter/foundation.dart';

class PlaybackProvider with ChangeNotifier {
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;

  void setPlayingState(bool isPlaying) {
    _isPlaying = isPlaying;
    notifyListeners();
  }

  void setDuration(Duration duration) {
    _duration = duration;
    notifyListeners();
  }

  void setPosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  void clear() {
    _isPlaying = false;
    _duration = Duration.zero;
    _position = Duration.zero;
    notifyListeners();
  }
}