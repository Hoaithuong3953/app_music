import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../service/client/song_service.dart';
import '../../models/song.dart';

class AdminShowSongPage extends StatefulWidget {
  final String songId;

  const AdminShowSongPage({super.key, required this.songId});

  @override
  _AdminShowSongPageState createState() => _AdminShowSongPageState();
}

class _AdminShowSongPageState extends State<AdminShowSongPage> {
  Song? song;
  List<dynamic> likedUsers = [];
  bool isLoading = true;
  bool isRateLimited = false;
  final SongService _songService = SongService();

  @override
  void initState() {
    super.initState();
    fetchSongDetails();
  }

  Future<void> fetchSongDetails({int retryCount = 0, int maxRetries = 3}) async {
    if (retryCount >= maxRetries) {
      setState(() {
        isLoading = false;
        isRateLimited = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Too many requests. Please try again later.')),
      );
      return;
    }

    try {
      final song = await _songService.getSong(widget.songId);
      setState(() {
        this.song = song;
        isLoading = false;
      });
      // Chỉ gọi fetchLikedUsers sau khi lấy được chi tiết bài hát
      await fetchLikedUsers();
    } catch (e) {
      if (e.toString().contains('429')) {
        // Đợi 1 giây trước khi thử lại
        await Future.delayed(const Duration(seconds: 1));
        await fetchSongDetails(retryCount: retryCount + 1, maxRetries: maxRetries);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading song: $e')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchLikedUsers() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final songResponse = await http.get(
        Uri.parse('http://localhost:8080/api/v1/song/${widget.songId}'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
      );

      if (songResponse.statusCode == 200) {
        final songData = jsonDecode(songResponse.body)['data'];
        final userIds = songData['likes'] is List ? songData['likes'] : [];
        if (userIds.isNotEmpty) {
          final response = await http.get(
            Uri.parse('http://localhost:8080/api/v1/user?_id=${userIds.join(',')}'),
            headers: {
              'Authorization': 'Bearer ${userProvider.user?.token}',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            setState(() {
              likedUsers = data['data'] is List ? data['data'] : [];
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load liked users: ${response.statusCode}')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load song data: ${songResponse.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading liked users: $e')),
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
          const SnackBar(content: Text('Song deleted successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete song')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> updateSong(Map<String, dynamic> songData, File? songFile, File? coverFile) async {
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

      if (songFile != null) {
        request.files.add(await http.MultipartFile.fromPath('song', songFile.path));
      }

      if (coverFile != null) {
        request.files.add(await http.MultipartFile.fromPath('cover', coverFile.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song updated successfully')),
        );
        fetchSongDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update song: $responseBody')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void showEditSongDialog() {
    final titleController = TextEditingController(text: song?.title);
    final artistController = TextEditingController(text: song?.artist);
    final genreController = TextEditingController(text: song?.genre.join(','));
    File? songFile;
    File? coverFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Song'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: artistController,
                decoration: const InputDecoration(labelText: 'Artist ID'),
              ),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(labelText: 'Genre IDs (comma-separated)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (result != null) {
                    songFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Song file selected')),
                    );
                  }
                },
                child: const Text('Select New Song File'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    coverFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cover image selected')),
                    );
                  }
                },
                child: const Text('Select New Cover Image'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required')),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(song != null ? song!.title : 'Song Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: song != null ? showEditSongDialog : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: song != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${song!.title}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteSong();
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
          : isRateLimited
              ? const Center(child: Text('Too many requests. Please try again later.'))
              : song == null
                  ? const Center(child: Text('Failed to load song'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (song!.coverImage != null)
                            Center(
                              child: Image.network(
                                song!.coverImage!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text('Title: ${song!.title}', style: const TextStyle(fontSize: 16)),
                          Text('Artist: ${song!.artist ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                          Text('Genres: ${song!.genre.join(', ')}', style: const TextStyle(fontSize: 16)),
                          Text('Duration: ${song!.duration ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                          Text('Views: ${song!.views}', style: const TextStyle(fontSize: 16)),
                          Text('Trending Score: ${song!.trendingScore}', style: const TextStyle(fontSize: 16)),
                          Text('Created At: ${song!.createdAt.toLocal()}', style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 24),
                          const Text('Lyrics:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          song!.lyrics != null && song!.lyrics!.isNotEmpty
                              ? SingleChildScrollView(
                                  child: Container(
                                    constraints: BoxConstraints(maxHeight: 200),
                                    child: Text(
                                      song!.lyrics!,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                                )
                              : const Text('No lyrics available', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 24),
                          const Text('Users Who Liked:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          likedUsers.isEmpty
                              ? const Center(child: Text('No users liked this song'))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: likedUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = likedUsers[index];
                                    return ListTile(
                                      leading: user['avatarImgURL'] != null
                                          ? CircleAvatar(
                                              backgroundImage: NetworkImage(user['avatarImgURL']),
                                            )
                                          : const Icon(Icons.person),
                                      title: Text('${user['firstName']} ${user['lastName']}'),
                                      subtitle: Text(user['email']),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
    );
  }
}