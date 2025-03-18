import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/music_card.dart';
import '../widgets/album_card.dart';
import '../widgets/song_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> albums = [];
  List<dynamic> music = [];
  List<dynamic> songs = [];

  @override
  void initState() {
    super.initState();
    loadAlbums();
    loadMusic();
    loadSongs();
  }

  Future<void> loadAlbums() async {
    final String response = await rootBundle.loadString('assets/data/albums.json');
    final data = json.decode(response);
    setState(() {
      albums = data;
    });
  }

  Future<void> loadMusic() async {
    final String response = await rootBundle.loadString('assets/data/music.json');
    final data = json.decode(response);
    setState(() {
      music = data;
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
        title: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.music_note, color: Color(0xFFA6B9FF), size: 30),
            SizedBox(width: 8),
            Text("Hi, ", style: TextStyle(fontSize: 24, color: Colors.black)),
            Text("Thuong", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
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
              const Text("Popular", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: music.map((song) => MusicCard(
                    title: song['title'],
                    subtitle: song['description'],
                    color: const Color(0xFFA6B9FF),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Top Albums", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: albums.map((album) => AlbumCard(
                    imagePath: album['image'],
                    title: album['title'],
                    subtitle: album['description'],
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Recommended Songs", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Column(
                children: songs.map((song) => SongCard(
                  imagePath: song['image'],
                  title: song['title'],
                  artist: song['artist'],
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
