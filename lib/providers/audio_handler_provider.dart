import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import 'playback_provider.dart';
import 'song_provider.dart';

class AudioHandlerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PlaybackProvider _playbackProvider;
  final SongProvider _songProvider;

  AudioHandlerProvider(this._playbackProvider, this._songProvider) {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playbackProvider.setPlayingState(state == PlayerState.playing);
    });

    _audioPlayer.onDurationChanged.listen((d) {
      _playbackProvider.setDuration(d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      _playbackProvider.setPosition(p);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      // Tự động chuyển sang bài tiếp theo khi bài hiện tại kết thúc
      _songProvider.nextSong();
      final nextSong = _songProvider.currentSong;
      if (nextSong != null) {
        playSong(nextSong);
      }
    });
  }

  Future<void> playSong(Song song) async {
    if (song.url == null || song.url!.isEmpty) {
      throw Exception('Song URL is missing');
    }

    try {
      await _audioPlayer.play(UrlSource(song.url!));
    } catch (e) {
      throw Exception('Error playing audio: $e');
    }
  }

  Future<void> playPause() async {
    if (_playbackProvider.isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekBackward() async {
    final newPosition = _playbackProvider.position - Duration(seconds: 10);
    await _audioPlayer.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> seekForward() async {
    final newPosition = _playbackProvider.position + Duration(seconds: 10);
    await _audioPlayer.seek(newPosition > _playbackProvider.duration ? _playbackProvider.duration : newPosition);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _playbackProvider.clear();
  }

  // Thêm phương thức update để xử lý cập nhật từ PlaybackProvider
  void update(PlaybackProvider playbackProvider) {
    // Cập nhật trạng thái nếu cần khi PlaybackProvider thay đổi
    // Trong trường hợp này, không cần cập nhật gì thêm vì AudioHandlerProvider đã lắng nghe các sự kiện từ _audioPlayer
    // Nhưng cần đảm bảo phương thức này tồn tại để ChangeNotifierProxyProvider hoạt động
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}