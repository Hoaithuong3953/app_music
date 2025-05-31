import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import '../../providers/user_provider.dart';
import '../../service/admin/admin_song_service.dart';
import '../../models/song.dart';

class AdminShowSongPage extends StatefulWidget {
  final String songId;

  const AdminShowSongPage({super.key, required this.songId});

  @override
  _AdminShowSongPageState createState() => _AdminShowSongPageState();
}

class _AdminShowSongPageState extends State<AdminShowSongPage> {
  Song? song;
  bool isLoading = true;
  bool isRateLimited = false;
  final AdminSongService _songService = AdminSongService();
  
  // Quản lý phát nhạc
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  
  // Quản lý thời lượng bài hát
  Duration? songDuration;
  bool isLoadingDuration = true;

  @override
  void initState() {
    super.initState();
    fetchSongDetails();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> fetchSongDetails({int retryCount = 0, int maxRetries = 3}) async {
    if (retryCount >= maxRetries) {
      setState(() {
        isLoading = false;
        isRateLimited = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quá nhiều yêu cầu. Vui lòng thử lại sau.')),
      );
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final result = await _songService.getAllSongs(
        token: userProvider.user?.token ?? '',
        songId: widget.songId,
      );

      print('Fetched Songs Result: $result');

      final songsData = result['songs'] as List<dynamic>;
      final songData = songsData.firstWhere(
        (entry) => (entry['song'] as Song).id == widget.songId,
        orElse: () => <String, Object>{},
      );

      if (songData.isEmpty) {
        throw Exception('Không tìm thấy bài hát với ID: ${widget.songId}');
      }

      setState(() {
        song = songData['song'] as Song;
        isLoading = false;
      });

      // Lấy thời lượng bài hát từ URL
      if (song?.url != null) {
        await fetchSongDuration();
      } else {
        setState(() {
          isLoadingDuration = false;
        });
      }
    } catch (e) {
      if (e.toString().contains('429')) {
        await Future.delayed(const Duration(seconds: 1));
        await fetchSongDetails(retryCount: retryCount + 1, maxRetries: maxRetries);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bài hát: $e')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Hàm lấy thời lượng bài hát từ URL
  Future<void> fetchSongDuration() async {
    try {
      // Tải metadata của bài hát từ URL
      await _audioPlayer.setSource(UrlSource(song!.url!));
      final duration = await _audioPlayer.getDuration();
      setState(() {
        songDuration = duration;
        isLoadingDuration = false;
      });
    } catch (e) {
      print('Lỗi lấy thời lượng bài hát: $e');
      setState(() {
        isLoadingDuration = false;
      });
    }
  }

  // Hàm định dạng thời lượng thành phút:giây
  String formatDuration(Duration? duration) {
    if (duration == null) return 'Không rõ';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> togglePlayPause() async {
    if (song?.url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có URL để phát bài hát')),
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
        await _audioPlayer.play(UrlSource(song!.url!));
        setState(() {
          isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phát nhạc: $e')),
      );
    }
  }

  Future<void> deleteSong() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/v1/song/${widget.songId}'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bài hát thành công')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bài hát thất bại')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> updateSong(Map<String, dynamic> songData, File? songFile, PlatformFile? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://localhost:8080/api/v1/song/${widget.songId}'),
      );

      request.headers['Authorization'] = 'Bearer ${userProvider.user?.token}';

      songData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (songFile != null && !kIsWeb) {
        request.files.add(await http.MultipartFile.fromPath('song', songFile.path));
      }

      if (coverFile != null) {
        if (kIsWeb) {
          if (coverFile.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
              'cover',
              coverFile.bytes!,
              filename: coverFile.name,
            ));
          }
        } else {
          if (coverFile.path != null) {
            request.files.add(await http.MultipartFile.fromPath('cover', coverFile.path!));
          }
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật bài hát thành công')),
        );
        fetchSongDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật bài hát thất bại: $responseBody')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void showEditSongDialog() {
    final titleController = TextEditingController(text: song?.title);
    final artistController = TextEditingController(text: song?.artist);
    final genreController = TextEditingController(text: song?.genre.join(','));
    File? songFile;
    PlatformFile? coverFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa bài hát'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              TextField(
                controller: artistController,
                decoration: const InputDecoration(labelText: 'ID Nghệ sĩ'),
              ),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(labelText: 'ID Thể loại (phân cách bằng dấu phẩy)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (result != null) {
                    if (!kIsWeb) {
                      songFile = File(result.files.single.path!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chọn file bài hát')),
                      );
                    }
                  }
                },
                child: const Text('Chọn file bài hát mới'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    coverFile = result.files.single;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chọn ảnh bìa')),
                    );
                  }
                },
                child: const Text('Chọn ảnh bìa mới'),
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
            onPressed: () {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tiêu đề là bắt buộc')),
                );
                return;
              }
              final songData = {
                'title': titleController.text,
                'artist': artistController.text,
                'genre': genreController.text,
              };
              updateSong(songData, songFile, coverFile);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài hát'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: 'Chỉnh sửa',
            onPressed: () {
              // Mở dialog chỉnh sửa
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Xóa bài hát',
            onPressed: deleteSong,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : song == null
              ? const Center(child: Text('Không tìm thấy bài hát'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 700),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Ảnh bìa
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        song!.coverImage ?? '',
                                        width: isWide ? 220 : 160,
                                        height: isWide ? 220 : 160,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: isWide ? 220 : 160,
                                          height: isWide ? 220 : 160,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.music_note, size: 80),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Tên bài hát
                                  Text(
                                    song!.title,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  // Nghệ sĩ
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.person, size: 20, color: Colors.blue),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          song!.artistName ?? 'Không rõ nghệ sĩ',
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Thể loại
                                  if (song!.genreNames.isNotEmpty)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.category, size: 20, color: Colors.deepPurple),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            song!.genreNames.join(', '),
                                            style: const TextStyle(fontSize: 15, color: Colors.deepPurple),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  // Ngày tạo
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Tạo ngày ${song!.createdAt.day}/${song!.createdAt.month}/${song!.createdAt.year}',
                                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Lượt thích
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.favorite, size: 18, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Lượt thích: ${song!.likes.length}',
                                        style: const TextStyle(fontSize: 15, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Nút phát nhạc
                                  ElevatedButton.icon(
                                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                                    label: Text(isPlaying ? 'Tạm dừng' : 'Phát nhạc'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(fontSize: 18),
                                    ),
                                    onPressed: togglePlayPause,
                                  ),
                                  const SizedBox(height: 16),
                                  // Thời lượng
                                  Text(
                                    'Thời lượng: ${formatDuration(songDuration)}',
                                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 24),
                                  // Lời bài hát
                                  if (song!.lyrics != null && song!.lyrics!.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        song!.lyrics!,
                                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}