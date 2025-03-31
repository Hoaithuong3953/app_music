import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentSongUrl;

  ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  ValueNotifier<Map<String, String>?> currentSongData = ValueNotifier<Map<String, String>?>(null);
  ValueNotifier<double> audioPosition = ValueNotifier<double>(0.0);
  ValueNotifier<double> totalTime = ValueNotifier<double>(0.0);

  AudioPlayerManager._internal() {
    _audioPlayer.onPositionChanged.listen((Duration p) {
      audioPosition.value = p.inSeconds.toDouble();
    });

    _audioPlayer.onDurationChanged.listen((Duration d) {
      totalTime.value = d.inSeconds.toDouble();
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      isPlayingNotifier.value = (state == PlayerState.playing);
    });
  }

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
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (_currentSongUrl == null) return;

      if (isPlayingNotifier.value) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      print("Error toggling play/pause: $e");
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSongUrl = null;
    currentSongData.value = null;
  }

  void seekTo(double position) {
    _audioPlayer.seek(Duration(seconds: position.toInt()));
  }
}