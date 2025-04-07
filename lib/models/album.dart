import 'package:app_music/models/song.dart';

import 'artist.dart';
import 'genre.dart';

class Album {
  final String id;
  final String title;
  final String slugify;
  final String? coverImageUrl;
  final Artist? artist; // Tham chiếu Artist
  final Genre? genre;   // Tham chiếu Genre
  final List<Song>? songs; // Danh sách tham chiếu Song
  final DateTime createdAt;
  final DateTime updatedAt;

  Album({
    required this.id,
    required this.title,
    required this.slugify,
    this.coverImageUrl,
    this.artist,
    this.genre,
    this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['_id'],
      title: json['title'],
      slugify: json['slugify'],
      coverImageUrl: json['coverImageURL'],
      artist: json['artist'] != null
          ? (json['artist'] is String
          ? Artist(id: json['artist'], title: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Artist.fromJson(json['artist']))
          : null,
      genre: json['genre'] != null
          ? (json['genre'] is String
          ? Genre(id: json['genre'], name: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Genre.fromJson(json['genre']))
          : null,
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