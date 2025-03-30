import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../service/user_service.dart';
import '../widgets/artist_card.dart';
import '../widgets/song_card.dart';
import '../widgets/playlist_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> playlists = [];
  List<dynamic> artists = [];
  List<dynamic> songs = [];
  String _username = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    loadPlaylists();
    loadArtists();
    loadSongs();
  }

  Future<void> _loadUserInfo() async {
    try {
      final String baseUrl = "http://10.0.2.2:8080"; // Thay bằng URL thật của bạn
      final userService = UserService(baseUrl: baseUrl);
      final userData = await userService.getCurrentUser();
      print('User Data: $userData');  // Log để xem dữ liệu trả về
      setState(() {
        _username = userData['response']['firstName'] ?? "User";  // Truy cập đúng trường 'response'
      });
    } catch (e) {
      print("Không thể lấy thông tin người dùng: $e");
      setState(() {
        _username = "User"; // Mặc định nếu không lấy được dữ liệu
      });
    }
  }

  Future<void> loadPlaylists() async {
    final String response = await rootBundle.loadString('assets/data/playlists.json');
    final data = json.decode(response);
    setState(() {
      playlists = data;
    });
  }

  Future<void> loadArtists() async {
    final String response = await rootBundle.loadString('assets/data/artists.json');
    final data = json.decode(response);
    setState(() {
      artists = data;
    });
  }

  Future<void> loadSongs() async {
    final String response = await rootBundle.loadString('assets/data/songs.json');
    final data = json.decode(response);
    setState(() {
      songs = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, color: Color(0xFFA6B9FF), size: 30),
            const SizedBox(width: 8),
            const Text("Hi, ", style: TextStyle(fontSize: 24, color: Colors.black)),
            Text(
              _username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Search music",
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Popular Playlists
              const Text("Popular Playlists", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: playlists.map((playlist) => PlaylistCard(
                    imagePath: playlist['image'],
                    title: playlist['title'],
                    description: playlist['description'],
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Top Artists
              // Top Artists Section
              const Text("Top Artists", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: artists.map((artist) => ArtistCard(
                    imagePath: artist['image'],
                    name: artist['name'],
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Recommended Songs
              const Text("Recommended Songs", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Column(
                children: songs.map((song) => SongCard(
                  imagePath: song['image'],
                  title: song['title'],
                  artist: song['artist'],
                )).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
