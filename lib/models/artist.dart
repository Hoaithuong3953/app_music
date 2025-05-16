class Artist {
  final String id;
  final String title;
  final String? avatar;
  final String slugify;
  final List<String> genres; // Danh sách tham chiếu đến Genre (ObjectId)
  final List<String> albums; // Danh sách tham chiếu đến Album (ObjectId)
  final List<String> songs;  // Danh sách tham chiếu đến Song (ObjectId)
  final DateTime createdAt;
  final DateTime updatedAt;

  Artist({
    required this.id,
    required this.title,
    this.avatar,
    required this.slugify,
    this.genres = const [],
    this.albums = const [],
    this.songs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      slugify: json['slugify']?.toString() ?? '',
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      albums: (json['albums'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      songs: (json['songs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'avatar': avatar,
      'slugify': slugify,
      'genres': genres,
      'albums': albums,
      'songs': songs,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}