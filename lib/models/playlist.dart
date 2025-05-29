import 'song.dart';
import 'user.dart';

class Playlist {
  final String id;
  final String title;
  final String? slugify;
  final String? coverImageURL;
  final dynamic user;
  final List<dynamic> songs; // Sửa thành List<dynamic> để linh hoạt hơn
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
      user: json['user'] == null
          ? throw Exception('User is required')
          : (json['user'] is Map<String, dynamic> ? User.fromJson(json['user']) : json['user']?.toString()),
      songs: (json['songs'] as List<dynamic>?)?.map((e) => e is Map<String, dynamic> ? Song.fromJson(e) : e.toString()).toList() ?? [],
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
      'songs': songs.map((e) => e is Song ? e.toJson() : e).toList(),
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Playlist copyWith({
    String? id,
    String? title,
    String? slugify,
    String? coverImageURL,
    dynamic user,
    List<dynamic>? songs, // Sửa thành List<dynamic>
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