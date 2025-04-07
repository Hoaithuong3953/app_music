import 'album.dart';
import 'artist.dart';
import 'genre.dart';

class Song {
  final String id;
  final String title;
  final Artist? artist; // Tham chiếu Artist
  final Album? album;   // Tham chiếu Album
  final List<Genre>? genre; // Danh sách tham chiếu Genre
  final String? duration;
  final String? slugify;
  final String? url;
  final String? coverImage;
  final List<String>? likes; // Danh sách ID User
  final List<Comment>? comments; // Danh sách bình luận
  final DateTime createdAt;
  final DateTime updatedAt;

  Song({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.genre,
    this.duration,
    this.slugify,
    this.url,
    this.coverImage,
    this.likes,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id'],
      title: json['title'],
      artist: json['artist'] != null
          ? (json['artist'] is String
          ? Artist(id: json['artist'], title: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Artist.fromJson(json['artist']))
          : null,
      album: json['album'] != null
          ? (json['album'] is String
          ? Album(id: json['album'], title: '', slugify: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Album.fromJson(json['album']))
          : null,
      genre: json['genre'] != null
          ? (json['genre'] as List)
          .map((g) => g is String
          ? Genre(id: g, name: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
          : Genre.fromJson(g))
          .toList()
          : null,
      duration: json['duration'],
      slugify: json['slugify'],
      url: json['url'],
      coverImage: json['coverImage'],
      likes: json['likes'] != null ? List<String>.from(json['likes']) : null,
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => Comment.fromJson(c)).toList()
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Comment {
  final String user; // ID User
  final String text;
  final DateTime createdAt;

  Comment({
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      user: json['user'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }
}