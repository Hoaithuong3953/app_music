import 'package:flutter/material.dart';

class Song {
  final String id;
  final String title;
  final String? description;
  final String? lyrics;
  final String? artist; // Lưu artist ID
  final String? artistName; // Lưu artist name
  final String? album;
  final List<String> genre; // Lưu genre IDs
  final List<String> genreNames; // Lưu genre names
  final String? duration;
  final String? slugify;
  final String? url;
  final String? coverImage;
  final int views;
  final int dailyViews;
  final int weeklyViews;
  final int trendingScore;
  final DateTime lastReset;
  final List<String> likes;
  final List<String> dislikes;
  final List<Comment> comments;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Song({
    required this.id,
    required this.title,
    this.description,
    this.lyrics,
    this.artist,
    this.artistName,
    this.album,
    this.genre = const [],
    this.genreNames = const [],
    this.duration,
    this.slugify,
    this.url,
    this.coverImage,
    this.views = 0,
    this.dailyViews = 0,
    this.weeklyViews = 0,
    this.trendingScore = 0,
    required this.lastReset,
    this.likes = const [],
    this.dislikes = const [],
    this.comments = const [],
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    print('Song.fromJson: $json'); // Debug
    final genreList = (json['genre'] as List<dynamic>?) ?? [];
    final genreNamesList = genreList.map((e) {
      if (e is Map<String, dynamic> && e['title'] != null) {
        return e['title'].toString();
      } else if (e is Map<String, dynamic> && e['_id'] != null) {
        return 'Thể loại không xác định (ID: ${e['_id']})';
      } else {
        return 'Thể loại không xác định';
      }
    }).toList();

    return Song(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      lyrics: json['lyrics']?.toString(),
      artist: json['artist'] is Map<String, dynamic>
          ? json['artist']['_id']?.toString()
          : json['artist']?.toString(),
      artistName: json['artist'] is Map<String, dynamic>
          ? json['artist']['title']?.toString() ?? 'Không rõ nghệ sĩ'
          : json['artist']?.toString() ?? 'Không rõ nghệ sĩ',
      album: json['album'] is Map<String, dynamic>
          ? json['album']['_id']?.toString()
          : json['album']?.toString(),
      genre: genreList.map((e) => e is Map<String, dynamic> ? e['_id']?.toString() ?? '' : e.toString()).toList(),
      genreNames: genreNamesList,
      duration: json['duration']?.toString(),
      slugify: json['slugify']?.toString(),
      url: json['url']?.toString(),
      coverImage: json['coverImage']?.toString(),
      views: json['views']?.toInt() ?? 0,
      dailyViews: json['dailyViews']?.toInt() ?? 0,
      weeklyViews: json['weeklyViews']?.toInt() ?? 0,
      trendingScore: json['trendingScore']?.toInt() ?? 0,
      lastReset: DateTime.tryParse(json['lastReset']?.toString() ?? '') ?? DateTime.now(),
      likes: (json['likes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      dislikes: (json['dislikes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      comments: (json['comments'] as List<dynamic>?)?.map((e) => Comment.fromJson(e)).toList() ?? [],
      isPublic: json['isPublic'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'lyrics': lyrics,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'slugify': slugify,
      'url': url,
      'coverImage': coverImage,
      'views': views,
      'dailyViews': dailyViews,
      'weeklyViews': weeklyViews,
      'trendingScore': trendingScore,
      'lastReset': lastReset.toIso8601String(),
      'likes': likes,
      'dislikes': dislikes,
      'comments': comments.map((e) => e.toJson()).toList(),
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
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
    return Comment(
      user: json['user']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}