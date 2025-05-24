import 'package:music_player_app/models/song.dart';

class RankingSong {
  final Song song;
  final String artist;
  final List<String> genre;
  final int rank;
  final double score;

  RankingSong({
    required this.song,
    required this.artist,
    required this.genre,
    required this.rank,
    required this.score,
  });

  factory RankingSong.fromJson(Map<String, dynamic> json) {
    return RankingSong(
      song: Song.fromJson(json),
      artist: json['artist']?['title'] ?? 'Unknown',
      genre: (json['genre'] as List<dynamic>?)?.map((g) => g['title'] as String).toList() ?? [],
      rank: json['rank'] as int,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': song.id,
      'title': song.title,
      'url': song.url,
      'coverImage': song.coverImage,
      'artist': {'title': artist},
      'genre': genre.map((g) => {'title': g}).toList(),
      'rank': rank,
      'score': score,
    };
  }
}