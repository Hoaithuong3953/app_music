import 'package:flutter/material.dart';
import '../../models/song.dart';

class PlayerPage extends StatefulWidget {
  final Song? song; // Đổi thành nullable để xử lý an toàn

  const PlayerPage({this.song, super.key});

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool isWishlisted = false;

  void toggleWishlist() {
    setState(() {
      isWishlisted = !isWishlisted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Kiểm tra song có null không
    if (widget.song == null) {
      return Scaffold(
        body: Center(child: Text('Error: No song provided')),
      );
    }

    return Scaffold(
      body: Container(
        color: Colors.white, // Background màu trắng
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start, // Chỉ giữ icon back
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        size: screenHeight * 0.035,
                        color: Theme.of(context).highlightColor,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                // Chiếm 90% chiều cao màn hình
                Expanded(
                  flex: 9, // 9/10 phần màn hình
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      // Căn giữa hình ảnh bài hát
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Căn giữa hình ảnh
                        children: [
                          Container(
                            width: screenWidth * 0.75,
                            height: screenWidth * 0.75,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.music_note,
                                size: screenWidth * 0.3,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      // Tăng lề hai bên cho phần chứa song, artist, wishlist
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: screenHeight * 0.045,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      child: Text(
                                        widget.song?.title ?? 'Unknown Title',
                                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontSize: screenHeight * 0.035,
                                          color: Theme.of(context).highlightColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  SizedBox(
                                    height: screenHeight * 0.03,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      child: Text(
                                        widget.song?.artist ?? 'Unknown Artist',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: screenHeight * 0.02,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isWishlisted ? Icons.favorite : Icons.favorite_border,
                                size: screenHeight * 0.035,
                                color: isWishlisted ? Colors.red : Theme.of(context).highlightColor,
                              ),
                              onPressed: toggleWishlist,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Slider(
                              value: 0,
                              min: 0,
                              max: 100,
                              activeColor: Theme.of(context).highlightColor,
                              inactiveColor: Colors.grey[300],
                              onChanged: (value) {},
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '0:00',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: screenHeight * 0.018,
                                  ),
                                ),
                                Text(
                                  widget.song?.duration ?? '0:00',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: screenHeight * 0.018,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.shuffle,
                                    size: screenHeight * 0.035,
                                    color: Theme.of(context).highlightColor,
                                  ),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.skip_previous,
                                    size: screenHeight * 0.045,
                                    color: Theme.of(context).highlightColor,
                                  ),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.play_circle_filled,
                                    size: screenHeight * 0.07,
                                    color: Theme.of(context).highlightColor,
                                  ),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.skip_next,
                                    size: screenHeight * 0.045,
                                    color: Theme.of(context).highlightColor,
                                  ),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.repeat,
                                    size: screenHeight * 0.035,
                                    color: Theme.of(context).highlightColor,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // Khoảng trống cuối cùng (1/10 màn hình)
              ],
            ),
          ),
        ),
      ),
    );
  }
}