class Genre {
  final String id;
  final String title;
  final String description;
  final String slugify;
  final String coverImage;
  final List<String> songs; // Danh sách tham chiếu đến Song (ObjectId)
  final DateTime createdAt;
  final DateTime updatedAt;

  Genre({
    required this.id,
    required this.title,
    required this.description,
    required this.slugify,
    required this.coverImage,
    this.songs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      slugify: json['slugify']?.toString() ?? '',
      coverImage: json['coverImage']?.toString() ?? 'https://media.istockphoto.com/id/1396814518/vector/image-coming-soon-no-photo-no-thumbnail-image-available-vector-illustration.jpg?s=612x612&w=0&k=20&c=hnh2OZgQGhf0b46-J2z7aHbIWwq8HNlSDaNp2wn_iko=',
      songs: (json['songs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'slugify': slugify,
      'coverImage': coverImage,
      'songs': songs,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}