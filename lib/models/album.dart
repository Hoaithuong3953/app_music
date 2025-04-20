import 'package:app_music/models/song.dart';
import 'package:app_music/models/artist.dart';
import 'package:app_music/models/genre.dart';

class Album {
  final String id;
  final String title;
  final String slugify;
  final String? coverImageURL;
  final Artist? artist;
  final Genre? genre;
  final List<Song>? songs;
  final DateTime createdAt;
  final DateTime updatedAt;

  Album({
    required this.id,
    required this.title,
    required this.slugify,
    this.coverImageURL,
    this.artist,
    this.genre,
    this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    try {
      return Album(
        id: json['_id'],
        title: json['title'],
        slugify: json['slugify'],
        coverImageURL: json['coverImageURL'],
        artist: json['artist'] != null ? Artist.fromJson(json['artist']) : null,
        genre: json['genre'] != null ? Genre.fromJson(json['genre']) : null,
        songs: json['songs'] != null
            ? (json['songs'] as List).map((song) => Song.fromJson(song)).toList()
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
    } catch (e) {
      throw FormatException('Error parsing Album JSON: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'slugify': slugify,
    'coverImageURL': coverImageURL,
    'artist': artist?.id,
    'genre': genre?.id,
    'songs': songs?.map((song) => song.id).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}