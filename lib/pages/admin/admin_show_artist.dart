import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../config/api_client.dart';
import '../../service/admin/admin_artist_service.dart';
import '../../service/client/song_service.dart';
import '../../service/admin/admin_genre_service.dart';
import '../../service/admin/admin_album_service.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../models/genre.dart';
import '../../providers/user_provider.dart';

class AdminShowArtistPage extends StatefulWidget {
  final String artistId;

  const AdminShowArtistPage({super.key, required this.artistId});

  @override
  AdminShowArtistPageState createState() => AdminShowArtistPageState();
}

class AdminShowArtistPageState extends State<AdminShowArtistPage> {
  Map<String, dynamic>? artistData;
  List<Map<String, dynamic>> songs = [];
  List<Map<String, dynamic>> albums = [];
  List<Map<String, dynamic>> genres = [];
  bool isLoading = true;
  final AdminArtistService _artistService = AdminArtistService();
  final SongService _songService = SongService();
  final AdminAlbumService _albumService = AdminAlbumService();
  final AdminGenreService _genreService = AdminGenreService();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    fetchArtistDetails();
  }

  Future<void> fetchArtistDetails() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fetchedArtistData = await _artistService.getArtistById(widget.artistId, token: userProvider.user?.token);
      List<Map<String, dynamic>> fetchedSongs = [];
      List<Map<String, dynamic>> fetchedAlbums = [];
      List<Map<String, dynamic>> fetchedGenres = [];

      // Lấy danh sách bài hát
      if (fetchedArtistData['artist'].songs.isNotEmpty) {
        final validSongIds = fetchedArtistData['artist'].songs.where((id) => id.isNotEmpty).toList();
        if (validSongIds.isNotEmpty) {
          final response = await _apiClient.get(
            'song/',
            queryParameters: {'_id[\$in]': validSongIds.join(',')}, // Sử dụng $in
            token: userProvider.user?.token,
          );
          if (response['success'] == true) {
            final songsData = response['data'] as List<dynamic>;
            fetchedSongs = songsData.map((json) {
              final song = Song.fromJson(json);
              return {
                'song': song,
                'artistName': json['artist']?['title']?.toString() ?? 'Không rõ nghệ sĩ',
              };
            }).toList();
          } else {
            print('Lỗi lấy bài hát: ${response['message']}');
          }
        }
      }

      // Lấy danh sách album
      if (fetchedArtistData['artist'].albums.isNotEmpty) {
        final validAlbumIds = fetchedArtistData['artist'].albums.where((id) => id.isNotEmpty).toList();
        if (validAlbumIds.isNotEmpty) {
          final response = await _apiClient.get(
            'album/',
            queryParameters: {'_id[\$in]': validAlbumIds.join(',')}, // Sử dụng $in
            token: userProvider.user?.token,
          );
          if (response['success'] == true) {
            final albumsData = response['data'] as List<dynamic>;
            fetchedAlbums = albumsData.map((json) {
              final album = Album.fromJson(json);
              return {
                'album': album,
                'artistName': json['artist']?['title']?.toString() ?? 'Không rõ nghệ sĩ',
              };
            }).toList();
          } else {
            print('Lỗi lấy album: ${response['message']}');
          }
        }
      }

      // Lấy danh sách thể loại
      if (fetchedArtistData['artist'].genres.isNotEmpty) {
        final validGenreIds = fetchedArtistData['artist'].genres.where((id) => id.isNotEmpty).toList();
        if (validGenreIds.isNotEmpty) {
          final response = await _apiClient.get(
            'genre/',
            queryParameters: {'_id[\$in]': validGenreIds.join(',')}, // Sử dụng $in
            token: userProvider.user?.token,
          );
          if (response['success'] == true) {
            final genresData = response['data'] as List<dynamic>;
            fetchedGenres = genresData.map((json) {
              final genre = Genre.fromJson(json);
              return {
                'genre': genre,
              };
            }).toList();
          } else {
            print('Lỗi lấy thể loại: ${response['message']}');
          }
        }
      }

      setState(() {
        artistData = fetchedArtistData;
        songs = fetchedSongs;
        albums = fetchedAlbums;
        genres = fetchedGenres;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      setState(() {
        artistData = null;
        songs = [];
        albums = [];
        genres = [];
        isLoading = false;
      });
    }
  }

  Future<void> deleteArtist() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _artistService.deleteArtist(
        artistId: widget.artistId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nghệ sĩ đã được xóa thành công')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> updateArtist() async {
    final titleController = TextEditingController(text: artistData!['artist'].title);
    File? avatarFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật Nghệ sĩ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tên nghệ sĩ'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    avatarFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ảnh đại diện đã được chọn')),
                    );
                  }
                },
                child: const Text('Chọn Ảnh Đại diện Mới'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tên nghệ sĩ là bắt buộc')),
                );
                return;
              }
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await _artistService.updateArtist(
                  artistId: widget.artistId,
                  title: titleController.text,
                  avatarPath: avatarFile?.path,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nghệ sĩ đã được cập nhật thành công')),
                );
                Navigator.pop(context);
                fetchArtistDetails();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> addSongsToArtist() async {
    final allSongs = await _songService.getAllSongs();
    final selectedSongIds = <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Bài Hát cho Nghệ sĩ'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: allSongs.map((entry) {
                final song = entry['song'] as Song;
                return CheckboxListTile(
                  title: Text(song.title),
                  subtitle: Text(entry['artistName']),
                  value: selectedSongIds.contains(song.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedSongIds.add(song.id);
                      } else {
                        selectedSongIds.remove(song.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedSongIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng chọn ít nhất một bài hát')),
                );
                return;
              }
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await _artistService.addSongsToArtist(
                  artistId: widget.artistId,
                  songIds: selectedSongIds,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thêm bài hát thành công')),
                );
                Navigator.pop(context);
                fetchArtistDetails();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> addAlbumsToArtist() async {
    final allAlbums = await _albumService.getAllAlbums();
    final selectedAlbumIds = <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Album cho Nghệ sĩ'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: allAlbums.map((entry) {
                final album = entry['album'] as Album;
                return CheckboxListTile(
                  title: Text(album.title),
                  subtitle: Text(entry['artistName']),
                  value: selectedAlbumIds.contains(album.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedAlbumIds.add(album.id);
                      } else {
                        selectedAlbumIds.remove(album.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedAlbumIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng chọn ít nhất một album')),
                );
                return;
              }
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await _artistService.addAlbumsToArtist(
                  artistId: widget.artistId,
                  albumIds: selectedAlbumIds,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thêm album thành công')),
                );
                Navigator.pop(context);
                fetchArtistDetails();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> addGenreToArtist() async {
    final allGenres = await _genreService.getAllGenres();
    String? selectedGenreId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Thể Loại cho Nghệ sĩ'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: allGenres.map((entry) {
                final genre = entry['genre'] as Genre;
                return RadioListTile<String>(
                  title: Text(genre.title),
                  value: genre.id,
                  groupValue: selectedGenreId,
                  onChanged: (value) {
                    setState(() {
                      selectedGenreId = value;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedGenreId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng chọn một thể loại')),
                );
                return;
              }
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await _artistService.addGenreToArtist(
                  artistId: widget.artistId,
                  genreId: selectedGenreId!,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thêm thể loại thành công')),
                );
                Navigator.pop(context);
                fetchArtistDetails();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> removeSongFromArtist(String songId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _artistService.removeSongsFromArtist(
        artistId: widget.artistId,
        songIds: [songId],
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa bài hát thành công')),
      );
      fetchArtistDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> removeAlbumFromArtist(String albumId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _artistService.removeAlbumsFromArtist(
        artistId: widget.artistId,
        albumIds: [albumId],
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa album thành công')),
      );
      fetchArtistDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> removeGenreFromArtist(String genreId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _artistService.removeGenreFromArtist(
        artistId: widget.artistId,
        genreId: genreId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thể loại thành công')),
      );
      fetchArtistDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(artistData != null ? artistData!['artist'].title : 'Chi tiết Nghệ sĩ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: artistData != null ? updateArtist : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addSongsToArtist,
          ),
          IconButton(
            icon: const Icon(Icons.album),
            onPressed: addAlbumsToArtist,
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: addGenreToArtist,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: artistData != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận Xóa'),
                        content: Text('Bạn có chắc muốn xóa ${artistData!['artist'].title}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteArtist();
                              Navigator.pop(context);
                            },
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : artistData == null
              ? const Center(child: Text('Không thể tải thông tin nghệ sĩ'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (artistData!['artist'].avatar != null)
                        Center(
                          child: Image.network(
                            artistData!['artist'].avatar,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 150),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text('Tên: ${artistData!['artist'].title}', style: const TextStyle(fontSize: 16)),
                      Text('Tạo lúc: ${artistData!['artist'].createdAt.toLocal()}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      const Text('Bài hát:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      songs.isEmpty
                          ? const Center(child: Text('Không có bài hát nào'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: songs.length,
                              itemBuilder: (context, index) {
                                final entry = songs[index];
                                final song = entry['song'] as Song;
                                final artistName = entry['artistName'] as String;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        title: Text(song.title),
                                        subtitle: Text(artistName),
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          '/admin/song/:sid',
                                          arguments: song.id,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Xác nhận Xóa'),
                                            content: Text('Bạn có chắc muốn xóa ${song.title} khỏi nghệ sĩ này?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Hủy'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  removeSongFromArtist(song.id);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Xóa'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                      const SizedBox(height: 24),
                      const Text('Album:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      albums.isEmpty
                          ? const Center(child: Text('Không có album nào'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: albums.length,
                              itemBuilder: (context, index) {
                                final entry = albums[index];
                                final album = entry['album'] as Album;
                                final artistName = entry['artistName'] as String;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        title: Text(album.title),
                                        subtitle: Text(artistName),
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          '/admin/album/:aid',
                                          arguments: album.id,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Xác nhận Xóa'),
                                            content: Text('Bạn có chắc muốn xóa ${album.title} khỏi nghệ sĩ này?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Hủy'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  removeAlbumFromArtist(album.id);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Xóa'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                      const SizedBox(height: 24),
                      const Text('Thể loại:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      genres.isEmpty
                          ? const Center(child: Text('Không có thể loại nào'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: genres.length,
                              itemBuilder: (context, index) {
                                final entry = genres[index];
                                final genre = entry['genre'] as Genre;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        title: Text(genre.title),
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          '/admin/genre/:gid',
                                          arguments: genre.id,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Xác nhận Xóa'),
                                            content: Text('Bạn có chắc muốn xóa ${genre.title} khỏi nghệ sĩ này?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Hủy'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  removeGenreFromArtist(genre.id);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Xóa'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}