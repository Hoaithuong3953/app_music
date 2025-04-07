import 'package:app_music/models/song.dart';
import 'package:app_music/models/album.dart';
import 'package:app_music/models/genre.dart';

class Artist {
  final String id;
  final String title; // Đổi từ 'name' thành 'title' để khớp với backend
  final String? avatar;
  final String? slugify; // Thêm slugify từ schema backend
  final List<Genre>? genres; // Danh sách tham chiếu Genre
  final List<Album>? albums; // Danh sách tham chiếu Album
  final List<Song>? songs;   // Danh sách tham chiếu Song
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
    return Artist(
      id: json['_id'] ?? '', // Đảm bảo không null
      title: json['title'] ?? 'Unknown Artist', // Đổi từ 'name' thành 'title', có giá trị mặc định
      avatar: json['avatar'],
      slugify: json['slugify'], // Thêm slugify
      genres: json['genres'] != null
          ? (json['genres'] as List)
          .map((genre) => genre is String
          ? Genre(
          id: genre,
          name: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now())
          : Genre.fromJson(genre))
          .toList()
          : null,
      albums: json['albums'] != null
          ? (json['albums'] as List)
          .map((album) => album is String
          ? Album(
          id: album,
          title: '',
          slugify: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now())
          : Album.fromJson(album))
          .toList()
          : null,
      songs: json['songs'] != null
          ? (json['songs'] as List)
          .map((song) => song is String
          ? Song(
          id: song,
          title: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now())
          : Song.fromJson(song))
          .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(), // Giá trị mặc định nếu null
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(), // Giá trị mặc định nếu null
    );
  }
}