class Playlist {
  final String id;
  final String title;
  final String slugify;
  final String? coverImageURL;
  final String user; // Tham chiếu đến User (ObjectId)
  final List<String> songs; // Danh sách tham chiếu đến Song (ObjectId)
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.title,
    required this.slugify,
    this.coverImageURL,
    required this.user,
    this.songs = const [],
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slugify: json['slugify']?.toString() ?? '',
      coverImageURL: json['coverImageURL']?.toString(),
      user: json['user']?.toString() ?? '',
      songs: (json['songs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isPublic: json['isPublic'] == true,
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
      'user': user,
      'songs': songs,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}