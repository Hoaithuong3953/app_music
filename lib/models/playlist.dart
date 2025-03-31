import 'package:app_music/models/song.dart';
import 'package:app_music/models/user.dart';

class Playlist {
  final String id;
  final String title;
  final User user; // Tham chiếu User (bắt buộc)
  final List<Song>? songs; // Danh sách tham chiếu Song
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.title,
    required this.user,
    this.songs,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['_id'],
      title: json['title'],
      user: json['user'] is String
          ? User(
        id: json['user'],
        firstName: '',
        lastName: '',
        email: '',
        mobile: '',
        password: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
          : User.fromJson(json['user']),
      songs: json['songs'] != null
          ? (json['songs'] as List)
          .map((song) => song is String
          ? Song(id: song, title: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Song.fromJson(song))
          .toList()
          : null,
      isPublic: json['isPublic'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}