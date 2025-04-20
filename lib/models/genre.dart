import 'package:app_music/models/song.dart';

class Genre {
  final String id;
  final String? title;
  final String? description;
  final String? coverImage;
  final List<Song>? songs;
  final DateTime createdAt;
  final DateTime updatedAt;

  Genre({
    required this.id,
    this.title,
    this.description,
    this.coverImage,
    this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    try {
      if (json['_id'] == null) {
        throw const FormatException('Missing required field: _id');
      }

      return Genre(
        id: json['_id'],
        title: json['title'] ?? 'Unknown Genre',
        description: json['description'],
        coverImage: json['coverImage'],
        songs: json['songs'] != null
            ? (json['songs'] as List)
            .map((s) {
          try {
            return Song.fromJson(s);
          } catch (e) {
            return null;
          }
        })
            .where((s) => s != null)
            .cast<Song>()
            .toList()
            : null,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      throw FormatException('Error parsing Genre JSON: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'coverImage': coverImage,
    'songs': songs?.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}