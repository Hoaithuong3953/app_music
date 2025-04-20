import 'package:app_music/models/album.dart';
import 'package:app_music/models/artist.dart';
import 'package:app_music/models/genre.dart';

class Song {
  final String id;
  final String title;
  final String? description;
  final String? lyrics;
  final Artist? artist;
  final Album? album;
  final List<Genre>? genres;
  final String? duration;
  final String? slugify;
  final String? url;
  final String? coverImage;
  final List<String>? likes;
  final List<Comment>? comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Song({
    required this.id,
    required this.title,
    this.description,
    this.lyrics,
    this.artist,
    this.album,
    this.genres,
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
    try {
      if (json['_id'] == null || json['title'] == null) {
        throw const FormatException('Missing required fields: _id or title');
      }

      return Song(
        id: json['_id'],
        title: json['title'],
        description: json['description'],
        lyrics: json['lyrics'],
        artist: json['artist'] != null ? Artist.fromJson(json['artist']) : null,
        album: json['album'] != null ? Album.fromJson(json['album']) : null,
        genres: json['genre'] != null
            ? (json['genre'] as List)
            .map((g) {
          try {
            final genre = Genre.fromJson(g is String ? {'_id': g} : g);
            return genre.title != null ? genre : null;
          } catch (e) {
            return null;
          }
        })
            .where((g) => g != null)
            .cast<Genre>()
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
    } catch (e) {
      throw FormatException('Error parsing Song JSON: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'lyrics': lyrics,
    'artist': artist?.id,
    'album': album?.id,
    'genre': genres?.map((g) => g.id).toList(),
    'duration': duration,
    'slugify': slugify,
    'url': url,
    'coverImage': coverImage,
    'likes': likes,
    'comments': comments?.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class Comment {
  final String user;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      return Comment(
        user: json['user'],
        text: json['text'],
        createdAt: DateTime.parse(json['createdAt']),
      );
    } catch (e) {
      throw FormatException('Error parsing Comment JSON: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}