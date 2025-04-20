import 'package:app_music/models/song.dart';
import 'package:app_music/models/album.dart';
import 'package:app_music/models/genre.dart';

class Artist {
  final String id;
  final String title;
  final String? avatar;
  final String? slugify;
  final List<Genre>? genres;
  final List<Album>? albums;
  final List<Song>? songs;
  final DateTime createdAt;
  final DateTime updatedAt;

  Artist({
    required this.id,
    required this.title,
    this.avatar,
    this.slugify,
    this.genres,
    this.albums,
    this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    try {
      return Artist(
        id: json['_id'],
        title: json['title'] ?? 'Unknown Artist',
        avatar: json['avatar'],
        slugify: json['slugify'],
        genres: json['genres'] != null
            ? (json['genres'] as List).map((genre) => Genre.fromJson(genre)).toList()
            : null,
        albums: json['albums'] != null
            ? (json['albums'] as List).map((album) => Album.fromJson(album)).toList()
            : null,
        songs: json['songs'] != null
            ? (json['songs'] as List).map((song) => Song.fromJson(song)).toList()
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Error parsing Artist JSON: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'avatar': avatar,
    'slugify': slugify,
    'genres': genres?.map((genre) => genre.id).toList(),
    'albums': albums?.map((album) => album.id).toList(),
    'songs': songs?.map((song) => song.id).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}