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
        if (song.url == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có URL để phát bài hát')),
          );
          return;
        }
        await _audioPlayer.play(UrlSource(song.url!));
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
      if (song.url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có URL để phát bài hát')),
        );
        return;
      }
      await _audioPlayer.play(UrlSource(song.url!));
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist != null ? playlist!.title : 'Chi tiết playlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addSongsToPlaylist,
            tooltip: 'Thêm bài hát',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: playlist != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: Text('Bạn có chắc chắn muốn xóa "${playlist!.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              deletePlaylist();
                              Navigator.pop(context);
                            },
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
          ? const Center(child: CircularProgressIndicator())
          : playlist == null
              ? const Center(child: Text('Không thể tải playlist'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (playlist!.coverImageURL != null)
                        Center(
                          child: Image.network(
                            playlist!.coverImageURL!,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Nút phát toàn bộ playlist
                      Center(
                        child: ElevatedButton.icon(
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Tên: ${playlist!.title}', style: const TextStyle(fontSize: 16)),
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          'Người tạo: ${userName ?? 'Người dùng không xác định'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text('Công khai: ${playlist!.isPublic ? 'Có' : 'Không'}', style: const TextStyle(fontSize: 16)),
                      Text('Ngày tạo: ${playlist!.createdAt.toLocal()}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      const Text('Danh sách bài hát:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      songs.isEmpty
                          ? const Center(child: Text('Không có bài hát nào trong playlist này'))
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
                                      child: SongTile(
                                        song: song,
                                        artistName: artistName,
                                        index: index + 1,
                                        onTap: () => playSong(index),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Xác nhận xóa'),
                                            content: Text('Bạn có chắc chắn muốn xóa "${song.title}" khỏi playlist này?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Hủy'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  removeSongFromPlaylist(song.id);
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