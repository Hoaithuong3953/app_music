class Album {
  final String id;
  final String title;
  final String? artist;
  final String slugify;
  final String? genre;
  final String? coverImageURL;
  final List<String> songs;
  final bool isPublic;
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
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    print('Album.fromJson input: $json'); // Debug input JSON
    return Album(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: json['artist'] is Map<String, dynamic> ? json['artist']['_id']?.toString() : json['artist']?.toString(),
      slugify: json['slugify']?.toString() ?? '',
      genre: json['genre'] is Map<String, dynamic> ? json['genre']['_id']?.toString() : json['genre']?.toString(),
      coverImageURL: json['coverImageURL']?.toString(),
      songs: (json['songs'] as List<dynamic>?)?.map((e) => e is Map<String, dynamic> ? e['_id']?.toString() ?? '' : e.toString()).where((id) => id.isNotEmpty).toList() ?? [],
      isPublic: json['isPublic'] is bool ? json['isPublic'] : true,
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
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}