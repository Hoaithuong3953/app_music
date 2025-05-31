import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import '../../config/api_client.dart';
import '../../service/client/playlist_service.dart';
import '../../service/client/song_service.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../widgets/client/song_tile.dart';
import '../../providers/user_provider.dart';
import '../../service/admin/admin_playlist_service.dart'; // Thêm import

class AdminShowPlaylistPage extends StatefulWidget {
  final String playlistId;

  const AdminShowPlaylistPage({super.key, required this.playlistId});

  @override
  _AdminShowPlaylistPageState createState() => _AdminShowPlaylistPageState();
}

class _AdminShowPlaylistPageState extends State<AdminShowPlaylistPage> {
  Playlist? playlist;
  List<Map<String, dynamic>> songs = [];
  String? userName;
  bool isLoading = true;
  final AdminPlaylistService _adminPlaylistService = AdminPlaylistService(); // Thêm service
  final SongService _songService = SongService();
  final ApiClient _apiClient = ApiClient();

  // Quản lý phát nhạc cho playlist
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  int currentSongIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchPlaylistDetails();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> fetchPlaylistDetails() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final result = await _adminPlaylistService.getPlaylistById(
        playlistId: widget.playlistId,
        token: userProvider.user?.token ?? '',
      );

      final fetchedSongs = (result['playlist'] as Playlist).songs.map((song) {
        return {
          'song': song,
          'artistName': song.artistName ?? 'Nghệ sĩ không xác định',
        };
      }).toList();

      setState(() {
        playlist = result['playlist'] as Playlist;
        songs = fetchedSongs;
        userName = result['userName'] as String;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deletePlaylist() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _adminPlaylistService.deletePlaylist(
        playlistId: widget.playlistId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa playlist thành công')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> addSongsToPlaylist() async {
    final allSongs = await _songService.getAllSongs();
    final selectedSongIds = <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm bài hát vào playlist'),
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
                await _adminPlaylistService.addSongsToPlaylist(
                  playlistId: widget.playlistId,
                  songIds: selectedSongIds,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thêm bài hát thành công')),
                );
                Navigator.pop(context);
                fetchPlaylistDetails();
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

  Future<void> removeSongFromPlaylist(String songId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updatedSongIds = playlist!.songs.map((song) => song.id).toList()..remove(songId);
      final response = await _apiClient.put(
        'playlist/${widget.playlistId}',
        {'songs': updatedSongIds.join(',')},
        token: userProvider.user?.token,
      );
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bài hát thành công')),
        );
        fetchPlaylistDetails();
      } else {
        throw Exception(response['message'] ?? 'Không thể xóa bài hát');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  // Hàm phát toàn bộ playlist
  Future<void> playPlaylist() async {
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist không có bài hát nào để phát')),
      );
      return;
    }

    try {
      if (isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          isPlaying = false;
        });
      } else {
        final song = songs[currentSongIndex]['song'] as Song;
        final songUrl = _getValidSongUrl(song.url);
        if (songUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có URL để phát bài hát')),
          );
          return;
        }
        await _audioPlayer.play(UrlSource(songUrl));
        setState(() {
          isPlaying = true;
        });

        // Lắng nghe khi bài hát kết thúc để chuyển sang bài tiếp theo
        _audioPlayer.onPlayerComplete.listen((event) {
          setState(() {
            currentSongIndex = (currentSongIndex + 1) % songs.length;
            playPlaylist();
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phát nhạc: $e')),
      );
    }
  }

  // Hàm phát một bài hát cụ thể
  Future<void> playSong(int index) async {
    try {
      final song = songs[index]['song'] as Song;
      final songUrl = _getValidSongUrl(song.url);
      if (songUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có URL để phát bài hát')),
        );
        return;
      }
      await _audioPlayer.play(UrlSource(songUrl));
      setState(() {
        currentSongIndex = index;
        isPlaying = true;
      });

      // Lắng nghe khi bài hát kết thúc để chuyển sang bài tiếp theo
      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          currentSongIndex = (currentSongIndex + 1) % songs.length;
          playSong(currentSongIndex);
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phát nhạc: $e')),
      );
    }
  }

  // Hàm xử lý URL bài hát
  String? _getValidSongUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Nếu URL đã là URL đầy đủ
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Nếu URL là đường dẫn tương đối, thêm base URL
    final baseUrl = _apiClient.baseUrl;
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }
    return '$baseUrl/$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          playlist != null ? playlist!.title : 'Chi tiết Playlist',
          style: const TextStyle(
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0984E3)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0984E3)),
            onPressed: addSongsToPlaylist,
            tooltip: 'Thêm bài hát',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: playlist != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: Text('Bạn có chắc chắn muốn xóa "${playlist!.title}"?'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              deletePlaylist();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
            tooltip: 'Xóa playlist',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0984E3)),
              ),
            )
          : playlist == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Không tìm thấy playlist',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (playlist!.coverImageURL?.isNotEmpty ?? false)
                                Hero(
                                  tag: 'playlist-${playlist!.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      playlist!.coverImageURL!,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 200,
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.music_note,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              if (songs.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: playPlaylist,
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    isPlaying ? 'Tạm dừng' : 'Phát toàn bộ playlist',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0984E3),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              _buildInfoRow(Icons.title, 'Tên playlist', playlist!.title),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                Icons.person,
                                'Người tạo',
                                userName ?? 'Người dùng không xác định',
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                Icons.visibility,
                                'Trạng thái',
                                playlist!.isPublic ? 'Công khai' : 'Riêng tư',
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                Icons.calendar_today,
                                'Ngày tạo',
                                playlist!.createdAt.toLocal().toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Danh sách bài hát', Icons.music_note),
                      const Divider(height: 1),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: songs.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    'Không có bài hát nào trong playlist này',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: songs.length,
                                itemBuilder: (context, index) {
                                  final entry = songs[index];
                                  final song = entry['song'] as Song;
                                  final artistName = entry['artistName'] as String;
                                  return Dismissible(
                                    key: Key(song.id),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (direction) async {
                                      return await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Xác nhận xóa'),
                                          content: Text(
                                              'Bạn có chắc chắn muốn xóa "${song.title}" khỏi playlist này?'),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Hủy'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Xóa'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (direction) {
                                      removeSongFromPlaylist(song.id);
                                    },
                                    child: SongTile(
                                      song: song,
                                      artistName: artistName,
                                      index: index + 1,
                                      onTap: () => playSong(index),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0984E3)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0984E3)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}