class Song {
  final String id;
  final String title;
  final String? description;
  final String? lyrics;
  final String? artist; // Tham chiếu đến Artist (ObjectId)
  final String? album;  // Tham chiếu đến Album (ObjectId)
  final List<String> genre; // Danh sách tham chiếu đến Genre (ObjectId)
  final String? duration;
  final String? slugify;
  final String? url;
  final String? coverImage;
  final List<String> likes; // Danh sách tham chiếu đến User (ObjectId)
  final List<Comment> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Song({
    required this.id,
    required this.title,
    this.description,
    this.lyrics,
    this.artist,
    this.album,
    this.genre = const [],
    this.duration,
    this.slugify,
    this.url,
    this.coverImage,
    this.likes = const [],
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      lyrics: json['lyrics']?.toString(),
      // Parse artist từ object thành String (title của nghệ sĩ)
      artist: json['artist'] != null
          ? (json['artist'] is Map<String, dynamic> && json['artist']['title'] != null
          ? json['artist']['title'].toString()
          : json['artist'].toString())
          : null,
      album: json['album']?.toString(),
      genre: (json['genre'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      duration: json['duration']?.toString(),
      slugify: json['slugify']?.toString(),
      url: json['url']?.toString(),
      coverImage: json['coverImage']?.toString(),
      likes: (json['likes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      comments: (json['comments'] as List<dynamic>?)?.map((e) => Comment.fromJson(e)).toList() ?? [],
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
      'likes': likes,
      'comments': comments.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Comment {
  final String user; // Tham chiếu đến User (ObjectId)
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