import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_client.dart';
import '../../service/admin/admin_album_service.dart';
import '../../service/client/song_service.dart';
import '../../service/admin/admin_genre_service.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../models/genre.dart';
import '../../widgets/client/song_tile.dart';
import '../../providers/user_provider.dart';

class AdminShowAlbumPage extends StatefulWidget {
  final String albumId;

  const AdminShowAlbumPage({super.key, required this.albumId});

  @override
  _AdminShowAlbumPageState createState() => _AdminShowAlbumPageState();
}

class _AdminShowAlbumPageState extends State<AdminShowAlbumPage> {
  Map<String, dynamic>? albumData;
  List<Map<String, dynamic>> songs = [];
  bool isLoading = true;
  final AdminAlbumService _albumService = AdminAlbumService();
  final SongService _songService = SongService();
  final AdminGenreService _genreService = AdminGenreService();
  final ApiClient _apiClient = ApiClient();
  String? genreName;

  @override
  void initState() {
    super.initState();
    fetchAlbumDetails();
  }

  Future<void> fetchAlbumDetails() async {
    try {
      final fetchedAlbumData = await _albumService.getAlbumById(widget.albumId);
      List<Map<String, dynamic>> fetchedSongs = [];
      
      // Fetch genre name if genre ID exists
      if (fetchedAlbumData['album'].genre != null && fetchedAlbumData['album'].genre.isNotEmpty) {
        try {
          final genreData = await _genreService.getGenreDetails(fetchedAlbumData['album'].genre);
          setState(() {
            genreName = genreData['genre'].title;
          });
        } catch (e) {
          print('Error fetching genre: $e');
          setState(() {
            genreName = 'Không xác định';
          });
        }
      }

      if (fetchedAlbumData['album'].songs.isNotEmpty) {
        final validSongIds = fetchedAlbumData['album'].songs.where((id) => id.isNotEmpty && id != fetchedAlbumData['album'].id).toList();
        if (validSongIds.isNotEmpty) {
          // Fetch songs one by one to avoid the ObjectId casting error
          for (String songId in validSongIds) {
            try {
              final response = await _apiClient.get(
                'song/$songId',
                token: Provider.of<UserProvider>(context, listen: false).user?.token,
              );
              if (response['success'] == true) {
                final songData = response['data'];
                final song = Song.fromJson(songData);
                fetchedSongs.add({
                  'song': song,
                  'artistName': songData['artist']?['title']?.toString() ?? 'Unknown Artist',
                });
              }
            } catch (e) {
              print('Error fetching song $songId: $e');
            }
          }
        }
      }
      setState(() {
        albumData = fetchedAlbumData;
        songs = fetchedSongs;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        albumData = null;
        songs = [];
        isLoading = false;
      });
    }
  }

  Future<void> deleteAlbum() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _albumService.deleteAlbum(
        albumId: widget.albumId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> addSongsToAlbum() async {
    final allSongs = await _songService.getAllSongs();
    final selectedSongIds = <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Songs to Album'),
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedSongIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one song')),
                );
                return;
              }
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await _albumService.addSongsToAlbum(
                  albumId: widget.albumId,
                  songIds: selectedSongIds,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Songs added successfully')),
                );
                Navigator.pop(context);
                fetchAlbumDetails();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> removeSongFromAlbum(String songId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updatedSongIds = albumData!['album'].songs.where((id) => id != songId).toList();
      await _albumService.updateAlbum(
        albumId: widget.albumId,
        songIds: updatedSongIds,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song removed successfully')),
      );
      fetchAlbumDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> addGenreToAlbum() async {
    final allGenres = await _genreService.getAllGenres();
    String? selectedGenreId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Genre to Album'),
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedGenreId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a genre')),
                );
                return;
              }
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await _albumService.addGenreToAlbum(
                  albumId: widget.albumId,
                  genreId: selectedGenreId!,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Genre added successfully')),
                );
                Navigator.pop(context);
                fetchAlbumDetails();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(albumData != null ? albumData!['album'].title : 'Album Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addSongsToAlbum,
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: addGenreToAlbum,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: albumData != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${albumData!['album'].title}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteAlbum();
                              Navigator.pop(context);
                            },
                            child: const Text('Delete'),
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
          : albumData == null
              ? const Center(child: Text('Failed to load album'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (albumData!['album'].coverImageURL != null)
                        Center(
                          child: Image.network(
                            albumData!['album'].coverImageURL,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 200),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin cơ bản',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3436),
                                ),
                              ),
                              const Divider(),
                              _buildInfoRow('Tên album', albumData!['album'].title),
                              _buildInfoRow('Nghệ sĩ', albumData!['artistName'] ?? 'Chưa có'),
                              _buildInfoRow('Thể loại', genreName ?? 'Chưa có'),
                              _buildInfoRow('Ngày tạo', albumData!['album'].createdAt.toLocal().toString().split('.')[0]),
                              _buildInfoRow('Ngày cập nhật', albumData!['album'].updatedAt.toLocal().toString().split('.')[0]),
                              _buildInfoRow('Số bài hát', '${songs.length} bài'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Danh sách bài hát',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: addSongsToAlbum,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm bài hát'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0984E3),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      songs.isEmpty
                          ? const Center(child: Text('Không có bài hát nào trong album này'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: songs.length,
                              itemBuilder: (context, index) {
                                final entry = songs[index];
                                final song = entry['song'] as Song;
                                final artistName = entry['artistName'] as String;
                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0984E3).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Color(0xFF0984E3),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      song.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D3436),
                                      ),
                                    ),
                                    subtitle: Text(
                                      artistName,
                                      style: const TextStyle(
                                        color: Color(0xFF636E72),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.play_arrow, color: Color(0xFF0984E3)),
                                          onPressed: () {
                                            // TODO: Implement play functionality
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Xác nhận xóa'),
                                                content: Text('Bạn có chắc chắn muốn xóa bài hát "${song.title}" khỏi album này?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Hủy'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      removeSongFromAlbum(song.id);
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
                                    ),
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/admin/song/:sid',
                                      arguments: song.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF636E72),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2D3436),
              ),
            ),
          ),
        ],
      ),
    );
  }
}