import 'package:app_music/models/song.dart';

class Genre {
  final String id;
  final String name;
  final String? description;
  final String? slugify;
  final List<Song>? songs; // Danh sách tham chiếu Song
  final DateTime createdAt;
  final DateTime updatedAt;

  Genre({
    required this.id,
    required this.name,
    this.description,
    this.slugify,
    this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      slugify: json['slugify'],
      songs: json['songs'] != null
          ? (json['songs'] as List)
          .map((song) => song is String
          ? Song(id: song, title: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Song.fromJson(song))
          .toList()
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}