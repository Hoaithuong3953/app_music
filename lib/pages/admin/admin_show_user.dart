import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/user_provider.dart';
import '../../service/client/song_service.dart';
import '../../models/song.dart';

class AdminShowUserPage extends StatefulWidget {
  final String userId;

  const AdminShowUserPage({super.key, required this.userId});

  @override
  _AdminShowUserPageState createState() => _AdminShowUserPageState();
}

class _AdminShowUserPageState extends State<AdminShowUserPage> {
  dynamic user;
  List<Map<String, dynamic>> likedSongs = [];
  bool isLoading = true;
  final SongService _songService = SongService();

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    fetchLikedSongs();
  }

  Future<void> fetchUserDetails() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/user?_id=${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          user = data['data'] is List && data['data'].isNotEmpty ? data['data'][0] : null;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user: ${response.statusCode}')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchLikedSongs() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/song?likes=${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final songs = data['data'] is List ? data['data'] as List : [];
        setState(() {
          likedSongs = songs
              .where((song) => song is Map<String, dynamic>) // Đảm bảo song là Map
              .map<Map<String, dynamic>>((song) {
                try {
                  return {
                    'song': Song.fromJson(song as Map<String, dynamic>),
                    'artistName': song['artist']?['title']?.toString() ?? 'Unknown Artist',
                  };
                } catch (e) {
                  print('Error parsing song: $e');
                  return {};
                }
              })
              .where((map) => map.isNotEmpty) // Loại bỏ map rỗng
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load liked songs: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading liked songs: $e')),
      );
    }
  }

  Future<void> deleteUser() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/v1/user/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete user')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> updateUser(Map<String, dynamic> updatedData) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.put(
        Uri.parse('http://localhost:8080/api/v1/user/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        fetchUserDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void showEditUserDialog() {
    final emailController = TextEditingController(text: user['email']);
    final firstNameController = TextEditingController(text: user['firstName']);
    final lastNameController = TextEditingController(text: user['lastName']);
    final mobileController = TextEditingController(text: user['mobile']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
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
              final updatedData = {
                'email': emailController.text,
                'firstName': firstNameController.text,
                'lastName': lastNameController.text,
                'mobile': mobileController.text,
              };
              updateUser(updatedData);
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
        title: Text(user != null ? '${user['firstName']} ${user['lastName']}' : 'User Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: user != null ? showEditUserDialog : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: user != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${user['firstName']} ${user['lastName']}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteUser();
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
          : user == null
              ? const Center(child: Text('Failed to load user'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user['avatarImgURL'] != null)
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(user['avatarImgURL']),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text('Email: ${user['email']}', style: const TextStyle(fontSize: 16)),
                      Text('Mobile: ${user['mobile']}', style: const TextStyle(fontSize: 16)),
                      Text('Role: ${user['role']}', style: const TextStyle(fontSize: 16)),
                      Text('Address: ${user['address'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                      Text('Blocked: ${user['isBlocked'] ? 'Yes' : 'No'}', style: const TextStyle(fontSize: 16)),
                      Text('Created At: ${DateTime.parse(user['createdAt']).toLocal()}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      const Text('Liked Songs:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      likedSongs.isEmpty
                          ? const Center(child: Text('No liked songs'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: likedSongs.length,
                              itemBuilder: (context, index) {
                                final songEntry = likedSongs[index];
                                final song = songEntry['song'] as Song;
                                final artistName = songEntry['artistName'] as String;
                                return ListTile(
                                  leading: song.coverImage != null
                                      ? Image.network(song.coverImage!, width: 50, height: 50, fit: BoxFit.cover)
                                      : const Icon(Icons.music_note),
                                  title: Text(song.title),
                                  subtitle: Text(artistName),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}