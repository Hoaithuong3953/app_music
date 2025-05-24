import './song.dart';
import './user.dart';

class Playlist {
  final String id;
  final String title;
  final String? slugify;
  final String? coverImageURL;
  final dynamic user; // Có thể là String (ID) hoặc User
  final List<Song> songs;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.title,
    this.slugify,
    this.coverImageURL,
    this.user,
    this.songs = const [],
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slugify: json['slugify']?.toString(),
      coverImageURL: json['coverImageURL']?.toString(),
      user: json['user'] is Map<String, dynamic> ? User.fromJson(json['user']) : json['user']?.toString(),
      songs: (json['songs'] as List<dynamic>?)?.map((e) => Song.fromJson(e)).toList() ?? [],
      isPublic: json['isPublic'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'slugify': slugify,
      'coverImageURL': coverImageURL,
      'user': user is User ? (user as User).toJson() : user,
      'songs': songs.map((e) => e.toJson()).toList(),
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Thêm phương thức copyWith
  Playlist copyWith({
    String? id,
    String? title,
    String? slugify,
    String? coverImageURL,
    dynamic user,
    List<Song>? songs,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      slugify: slugify ?? this.slugify,
      coverImageURL: coverImageURL ?? this.coverImageURL,
      user: user ?? this.user,
      songs: songs ?? this.songs,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}