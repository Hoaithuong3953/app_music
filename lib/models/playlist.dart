import 'package:app_music/models/song.dart';
import 'package:app_music/models/user.dart';

class Playlist {
  final String id;
  final String title;
  final String? slugify;
  final String? coverImageURL;
  final User user;
  final List<Song>? songs;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.title,
    this.slugify,
    this.coverImageURL,
    required this.user,
    this.songs,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    try {
      return Playlist(
        id: json['_id'],
        title: json['title'],
        slugify: json['slugify'],
        coverImageURL: json['coverImageURL'],
        user: User.fromJson(json['user']),
        songs: json['songs'] != null
            ? (json['songs'] as List).map((song) => Song.fromJson(song)).toList()
            : null,
        isPublic: json['isPublic'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
    } catch (e) {
      throw FormatException('Error parsing Playlist JSON: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'slugify': slugify,
    'coverImageURL': coverImageURL,
    'user': user.id,
    'songs': songs?.map((song) => song.id).toList(),
    'isPublic': isPublic,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}