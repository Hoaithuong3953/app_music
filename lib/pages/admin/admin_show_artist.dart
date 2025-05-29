import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../config/api_client.dart';
import '../../service/admin/admin_artist_service.dart';
import '../../service/admin/admin_song_service.dart';
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
  String? errorMessage;
  final AdminArtistService _artistService = AdminArtistService();
  final AdminSongService _songService = AdminSongService();
  final AdminAlbumService _albumService = AdminAlbumService();
  final AdminGenreService _genreService = AdminGenreService();

  @override
  void initState() {
    super.initState();
    fetchArtistDetails();
  }

  Future<void> fetchArtistDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.user?.token;
      if (token == null) {
        throw Exception('Không có token xác thực.');
      }

      print('Fetching artist with ID: ${widget.artistId}');
      final fetchedArtistData = await _artistService.getArtistById(widget.artistId, token: token);
      print('Fetched Artist Data: $fetchedArtistData');
      print('Artist Songs: ${fetchedArtistData['artist'].songs}');
      print('Artist Albums: ${fetchedArtistData['artist'].albums}');
      print('Artist Genres: ${fetchedArtistData['artist'].genres}');

      List<Map<String, dynamic>> fetchedSongs = [];
      List<Map<String, dynamic>> fetchedAlbums = [];
      List<Map<String, dynamic>> fetchedGenres = [];

      // Lấy danh sách bài hát
      if (fetchedArtistData['artist'].songs != null && fetchedArtistData['artist'].songs.isNotEmpty) {
        final List<String> songIds = (fetchedArtistData['artist'].songs as List<dynamic>)
            .where((song) => song != null)
            .map((song) {
              final songId = song is Map ? song['_id']?.toString() ?? song.toString() : song.toString();
              print('Song ID from artist: $songId (Type: ${songId.runtimeType})');
              return songId;
            })
            .toList();
        print('Song IDs: $songIds');

        if (songIds.isNotEmpty) {
          final songsData = await _songService.getAllSongs(
            token: token,
            fields: 'title,artist,coverImage',
          );
          print('Songs Data: $songsData');
          print('Songs Data Type: ${songsData.runtimeType}');

          fetchedSongs = (songsData as List<dynamic>)
              .where((json) {
                final song = json['song'] as Song?;
                final songId = song?.id?.toString();
                print('Song ID from songsData: $songId (Type: ${songId.runtimeType})');
                final matches = songId != null && songIds.contains(songId);
                print('Matches for Song ID $songId: $matches');
                return matches;
              })
              .cast<Map<String, dynamic>>()
              .toList();
          print('Fetched Songs: $fetchedSongs');
        }
      }

      // Lấy danh sách album
      if (fetchedArtistData['artist'].albums != null && fetchedArtistData['artist'].albums.isNotEmpty) {
        final List<String> albumIds = (fetchedArtistData['artist'].albums as List<dynamic>)
            .where((album) => album != null)
            .map((album) {
              final albumId = album is Map ? album['_id']?.toString() ?? album.toString() : album.toString();
              print('Album ID from artist: $albumId (Type: ${albumId.runtimeType})');
              return albumId;
            })
            .toList();
        print('Album IDs: $albumIds');

        if (albumIds.isNotEmpty) {
          final albumsData = await _albumService.getAllAlbums(
            token: token,
            fields: 'title,artist',
          );
          print('Albums Data: $albumsData');
          print('Albums Data Type: ${albumsData.runtimeType}');

          fetchedAlbums = (albumsData as List<dynamic>)
              .where((json) {
                final album = json['album'] as Album?;
                final albumId = album?.id?.toString();
                print('Album ID from albumsData: $albumId (Type: ${albumId.runtimeType})');
                final matches = albumId != null && albumIds.contains(albumId);
                print('Matches for Album ID $albumId: $matches');
                return matches;
              })
              .cast<Map<String, dynamic>>()
              .toList();
          print('Fetched Albums: $fetchedAlbums');
        }
      }

      // Lấy danh sách thể loại
      if (fetchedArtistData['artist'].genres != null && fetchedArtistData['artist'].genres.isNotEmpty) {
        final List<String> genreIds = (fetchedArtistData['artist'].genres as List<dynamic>)
            .where((genre) => genre != null)
            .map((genre) {
              final genreId = genre is Map ? genre['_id']?.toString() ?? genre.toString() : genre.toString();
              print('Genre ID from artist: $genreId (Type: ${genreId.runtimeType})');
              return genreId;
            })
            .toList();
        print('Genre IDs: $genreIds');

        if (genreIds.isNotEmpty) {
          final genresData = await _genreService.getAllGenres(
            token: token,
            fields: 'title',
          );
          print('Genres Data: $genresData');
          print('Genres Data Type: ${genresData.runtimeType}');

          fetchedGenres = (genresData as List<dynamic>)
              .where((json) {
                final genre = json['genre'] as Genre?;
                final genreId = genre?.id?.toString();
                print('Genre ID from genresData: $genreId (Type: ${genreId.runtimeType})');
                final matches = genreId != null && genreIds.contains(genreId);
                print('Matches for Genre ID $genreId: $matches');
                return matches;
              })
              .cast<Map<String, dynamic>>()
              .toList();
          print('Fetched Genres: $fetchedGenres');
        }
      }

      if (mounted) {
        setState(() {
          artistData = fetchedArtistData;
          songs = fetchedSongs;
          albums = fetchedAlbums;
          genres = fetchedGenres;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          artistData = null;
          songs = [];
          albums = [];
          genres = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> deleteArtist() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _artistService.deleteArtist(
        artistId: widget.artistId,
        token: userProvider.user?.token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nghệ sĩ đã được xóa thành công')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
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
                child: const Text('Chọn Ảnh Đại Diện Mới'),
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nghệ sĩ đã được cập nhật thành công')),
                  );
                  Navigator.pop(context);
                  fetchArtistDetails();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> addSongsToArtist() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final allSongs = await _songService.getAllSongs(token: userProvider.user?.token ?? '');
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm bài hát thành công')),
                  );
                  Navigator.pop(context);
                  fetchArtistDetails();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> addAlbumsToArtist() async {
    final allAlbums = await _albumService.getAllAlbums(token: Provider.of<UserProvider>(context, listen: false).user?.token);
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm album thành công')),
                  );
                  Navigator.pop(context);
                  fetchArtistDetails();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> addGenreToArtist() async {
    final allGenres = await _genreService.getAllGenres(token: Provider.of<UserProvider>(context, listen: false).user?.token);
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm thể loại thành công')),
                  );
                  Navigator.pop(context);
                  fetchArtistDetails();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bài hát thành công')),
        );
        fetchArtistDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa album thành công')),
        );
        fetchArtistDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thể loại thành công')),
        );
        fetchArtistDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(artistData != null ? artistData!['artist'].title : 'Chi tiết Nghệ sĩ'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0984E3)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF0984E3)),
            onPressed: artistData != null ? updateArtist : null,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0984E3)),
            onPressed: addSongsToArtist,
            tooltip: 'Thêm bài hát',
          ),
          IconButton(
            icon: const Icon(Icons.album, color: Color(0xFF0984E3)),
            onPressed: addAlbumsToArtist,
            tooltip: 'Thêm album',
          ),
          IconButton(
            icon: const Icon(Icons.category, color: Color(0xFF0984E3)),
            onPressed: addGenreToArtist,
            tooltip: 'Thêm thể loại',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
            onPressed: artistData != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Xác nhận Xóa'),
                        content: Text('Bạn có chắc muốn xóa ${artistData!['artist'].title}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy', style: TextStyle(color: Color(0xFF636E72))),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteArtist();
                              Navigator.pop(context);
                            },
                            child: const Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C))),
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
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0984E3))))
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text('Lỗi: $errorMessage', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                )
              : artistData == null
                  ? const Center(
                      child: Text(
                        'Không thể tải thông tin nghệ sĩ',
                        style: TextStyle(fontSize: 18, color: Color(0xFF636E72)),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar Section
                          Center(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0984E3).withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 70,
                                backgroundColor: const Color(0xFF0984E3).withOpacity(0.1),
                                child: artistData!['artist'].avatar != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(70),
                                        child: Image.network(
                                          artistData!['artist'].avatar!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.person, size: 70, color: Color(0xFF0984E3)),
                                        ),
                                      )
                                    : Icon(Icons.person, size: 70, color: const Color(0xFF0984E3)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Artist Info Section
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, color: Color(0xFF0984E3), size: 24),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Thông tin nghệ sĩ',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3436)),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  _buildInfoRow('Tên', artistData!['artist'].title),
                                  _buildInfoRow(
                                    'Ngày tạo',
                                    artistData!['artist'].createdAt?.toLocal().toString().split('.')[0] ?? 'N/A',
                                  ),
                                  _buildInfoRow(
                                    'Cập nhật',
                                    artistData!['artist'].updatedAt?.toLocal().toString().split('.')[0] ?? 'N/A',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Songs Section
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.music_note, color: Color(0xFF0984E3), size: 24),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Bài hát',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3436)),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.refresh, color: Color(0xFF0984E3)),
                                        onPressed: fetchArtistDetails,
                                        tooltip: 'Làm mới danh sách',
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  if (songs.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          children: [
                                            Icon(Icons.music_note, size: 48, color: Colors.grey[400]),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Chưa có bài hát nào',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.builder(
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
                                                leading: song.coverImage != null
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.network(
                                                          song.coverImage!,
                                                          width: 50,
                                                          height: 50,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => Container(
                                                            width: 50,
                                                            height: 50,
                                                            color: Colors.grey[200],
                                                            child: const Icon(Icons.music_note),
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: 50,
                                                        height: 50,
                                                        color: Colors.grey[200],
                                                        child: const Icon(Icons.music_note),
                                                      ),
                                                title: Text(song.title),
                                                subtitle: Text(artistName),
                                                onTap: () => Navigator.pushNamed(
                                                  context,
                                                  '/admin/song/:sid',
                                                  arguments: song.id,
                                                ).then((_) => fetchArtistDetails()),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    title: const Text('Xác nhận Xóa'),
                                                    content: Text('Bạn có chắc muốn xóa ${song.title} khỏi nghệ sĩ này?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('Hủy', style: TextStyle(color: Color(0xFF636E72))),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          removeSongFromArtist(song.id);
                                                          Navigator.pop(context);
                                                        },
                                                        child: const Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C))),
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
                          ),
                          const SizedBox(height: 24),

                          // Albums Section
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.album, color: Color(0xFF0984E3), size: 24),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Album',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3436)),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  if (albums.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          children: [
                                            Icon(Icons.album, size: 48, color: Colors.grey[400]),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Chưa có album nào',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.builder(
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
                                                ).then((_) => fetchArtistDetails()),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    title: const Text('Xác nhận Xóa'),
                                                    content: Text('Bạn có chắc muốn xóa ${album.title} khỏi nghệ sĩ này?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('Hủy', style: TextStyle(color: Color(0xFF636E72))),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          removeAlbumFromArtist(album.id);
                                                          Navigator.pop(context);
                                                        },
                                                        child: const Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C))),
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
                          ),
                          const SizedBox(height: 24),

                          // Genres Section
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.category, color: Color(0xFF0984E3), size: 24),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Thể loại',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3436)),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  if (genres.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          children: [
                                            Icon(Icons.category, size: 48, color: Colors.grey[400]),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Chưa có thể loại nào',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.builder(
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
                                                ).then((_) => fetchArtistDetails()),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    title: const Text('Xác nhận Xóa'),
                                                    content: Text('Bạn có chắc muốn xóa ${genre.title} khỏi nghệ sĩ này?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('Hủy', style: TextStyle(color: Color(0xFF636E72))),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          removeGenreFromArtist(genre.id);
                                                          Navigator.pop(context);
                                                        },
                                                        child: const Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C))),
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
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF636E72), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? const Color(0xFF2D3436), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}