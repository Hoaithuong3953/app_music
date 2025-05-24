class Album {
  final String id;
  final String title;
  final String? artist; // Tham chiếu đến Artist (ObjectId)
  final String slugify;
  final String? genre;  // Tham chiếu đến Genre (ObjectId)
  final String? coverImageURL;
  final List<String> songs; // Danh sách tham chiếu đến Song (ObjectId)
  final DateTime createdAt;
  final DateTime updatedAt;

  Album({
    required this.id,
    required this.title,
    this.artist,
    required this.slugify,
    this.genre,
    this.coverImageURL,
    this.songs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: json['artist'] is Map<String, dynamic> ? json['artist']['_id']?.toString() : json['artist']?.toString(),
      slugify: json['slugify']?.toString() ?? '',
      genre: json['genre'] is Map<String, dynamic> ? json['genre']['_id']?.toString() : json['genre']?.toString(),
      coverImageURL: json['coverImageURL']?.toString(),
      songs: (json['songs'] as List<dynamic>?)?.map((e) => e is Map<String, dynamic> ? e['_id']?.toString() ?? '' : e.toString()).where((id) => id.isNotEmpty).toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'artist': artist,
      'slugify': slugify,
      'genre': genre,
      'coverImageURL': coverImageURL,
      'songs': songs,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}