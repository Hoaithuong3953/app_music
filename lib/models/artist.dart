import 'package:app_music/models/song.dart';

import 'album.dart';
import 'genre.dart';

class Artist {
  final String id;
  final String name;
  final String? bio;
  final String? avatar;
  final List<Genre>? genres; // Danh sách tham chiếu Genre
  final List<Album>? albums; // Danh sách tham chiếu Album
  final List<Song>? songs;   // Danh sách tham chiếu Song
  final DateTime createdAt;
  final DateTime updatedAt;

  Artist({
    required this.id,
    required this.name,
    this.bio,
    this.avatar,
    this.genres,
    this.albums,
    this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['_id'],
      name: json['name'],
      bio: json['bio'],
      avatar: json['avatar'],
      genres: json['genres'] != null
          ? (json['genres'] as List)
          .map((genre) => genre is String
          ? Genre(id: genre, name: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Genre.fromJson(genre))
          .toList()
          : null,
      albums: json['albums'] != null
          ? (json['albums'] as List)
          .map((album) => album is String
          ? Album(id: album, title: '', slugify: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Album.fromJson(album))
          .toList()
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