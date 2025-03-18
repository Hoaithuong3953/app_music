import 'package:flutter/material.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  double _currentTime = 135;
  final double _totalTime = 208;
  bool _isPlaying = false; // Trạng thái phát/dừng

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFA6B9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20), // Khoảng cách trên
            ClipRRect(
              borderRadius: BorderRadius.circular(16), // Giữ hình vuông bo góc
              child: Image.asset(
                'assets/images/song_1.jpg',
                width: double.infinity,
                height: MediaQuery.of(context).size.width - 40, // Đảm bảo hình vuông
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text("Blinding Lights", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("The Weeknd", style: TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 10),
            Slider(
              value: _currentTime,
              min: 0,
              max: _totalTime,
              activeColor: const Color(0xFFA6B9FF),
              onChanged: (value) {
                setState(() {
                  _currentTime = value;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${_currentTime.toInt() ~/ 60}:${(_currentTime.toInt() % 60).toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.black54)),
                  Text("${_totalTime.toInt() ~/ 60}:${(_totalTime.toInt() % 60).toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.shuffle, size: 30, color: Color(0xFFA6B9FF)), onPressed: () {}),
                IconButton(icon: const Icon(Icons.skip_previous, size: 40, color: Color(0xFFA6B9FF)), onPressed: () {}),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    size: 60,
                    color: const Color(0xFFA6B9FF),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPlaying = !_isPlaying; // Chuyển trạng thái phát/dừng
                    });
                  },
                ),
                IconButton(icon: const Icon(Icons.skip_next, size: 40, color: Color(0xFFA6B9FF)), onPressed: () {}),
                IconButton(icon: const Icon(Icons.repeat, size: 30, color: Color(0xFFA6B9FF)), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}