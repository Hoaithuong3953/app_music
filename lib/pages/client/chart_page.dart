import 'package:flutter/material.dart';
import '../../widgets/client/song_tile.dart';
import '../../models/song.dart';
import '../../service/client/song_service.dart';

class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> with SingleTickerProviderStateMixin {
  final SongService _songService = SongService();
  late TabController _tabController;

  // Danh sách bài hát cho từng tab
  List<Map<String, dynamic>> dailySongs = [];
  List<Map<String, dynamic>> weeklySongs = [];
  List<Map<String, dynamic>> monthlySongs = [];

  bool isLoadingDaily = true;
  bool isLoadingWeekly = true;
  bool isLoadingMonthly = true;

  String? errorMessageDaily;
  String? errorMessageWeekly;
  String? errorMessageMonthly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSongs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSongs() async {
    setState(() {
      isLoadingDaily = true;
      isLoadingWeekly = true;
      isLoadingMonthly = true;
      errorMessageDaily = null;
      errorMessageWeekly = null;
      errorMessageMonthly = null;
    });

    try {
      final fetchedSongs = await _songService.getAllSongs();
      if (fetchedSongs.isEmpty) {
        setState(() {
          errorMessageDaily = 'No songs available';
          errorMessageWeekly = 'No songs available';
          errorMessageMonthly = 'No songs available';
          isLoadingDaily = false;
          isLoadingWeekly = false;
          isLoadingMonthly = false;
        });
        return;
      }

      // Sắp xếp bài hát theo createdAt giảm dần (mới nhất trước)
      fetchedSongs.sort((a, b) {
        final songA = a['song'] as Song;
        final songB = b['song'] as Song;
        return songB.createdAt.compareTo(songA.createdAt);
      });

      // Giả lập dữ liệu cho từng tab
      final playsDaily = [1250000, 980000, 750000, 600000, 500000]; // Giả định số lần phát trong ngày
      final playsWeekly = [2500000, 1960000, 1500000, 1200000, 1000000]; // Giả định số lần phát trong tuần
      final playsMonthly = [5000000, 3920000, 3000000, 2400000, 2000000]; // Giả định số lần phát trong tháng

      // Giả lập lọc bài hát theo ngày, tuần, tháng
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Lọc bài hát theo ngày (giả lập: lấy 5 bài mới nhất)
      final dailyFiltered = fetchedSongs.take(5).toList();
      setState(() {
        dailySongs = dailyFiltered.asMap().entries.map((entry) {
          final index = entry.key;
          final songData = entry.value;
          final song = songData['song'] as Song;
          final artistName = songData['artistName'] as String;
          return {
            'song': song,
            'artistName': artistName,
            'plays': index < playsDaily.length ? playsDaily[index] : 500000 - index * 10000,
          };
        }).toList();
        isLoadingDaily = false;
      });

      // Lọc bài hát theo tuần (giả lập: lấy 10 bài mới nhất)
      final weeklyFiltered = fetchedSongs.take(10).toList();
      setState(() {
        weeklySongs = weeklyFiltered.asMap().entries.map((entry) {
          final index = entry.key;
          final songData = entry.value;
          final song = songData['song'] as Song;
          final artistName = songData['artistName'] as String;
          return {
            'song': song,
            'artistName': artistName,
            'plays': index < playsWeekly.length ? playsWeekly[index] : 1000000 - index * 20000,
          };
        }).toList();
        isLoadingWeekly = false;
      });

      // Lọc bài hát theo tháng (giả lập: lấy tất cả bài hát)
      final monthlyFiltered = fetchedSongs.toList();
      setState(() {
        monthlySongs = monthlyFiltered.asMap().entries.map((entry) {
          final index = entry.key;
          final songData = entry.value;
          final song = songData['song'] as Song;
          final artistName = songData['artistName'] as String;
          return {
            'song': song,
            'artistName': artistName,
            'plays': index < playsMonthly.length ? playsMonthly[index] : 2000000 - index * 40000,
          };
        }).toList();
        isLoadingMonthly = false;
      });
    } catch (e) {
      setState(() {
        errorMessageDaily = e.toString();
        errorMessageWeekly = e.toString();
        errorMessageMonthly = e.toString();
        isLoadingDaily = false;
        isLoadingWeekly = false;
        isLoadingMonthly = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Charts',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: screenHeight * 0.035,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).highlightColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).highlightColor,
          tabs: const [
            Tab(text: 'Day'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab Day
            _buildTabContent(
              context,
              isLoading: isLoadingDaily,
              errorMessage: errorMessageDaily,
              songs: dailySongs,
              title: 'Top Songs Today',
              screenHeight: screenHeight,
              screenWidth: screenWidth,
            ),
            // Tab Week
            _buildTabContent(
              context,
              isLoading: isLoadingWeekly,
              errorMessage: errorMessageWeekly,
              songs: weeklySongs,
              title: 'Top Songs This Week',
              screenHeight: screenHeight,
              screenWidth: screenWidth,
            ),
            // Tab Month
            _buildTabContent(
              context,
              isLoading: isLoadingMonthly,
              errorMessage: errorMessageMonthly,
              songs: monthlySongs,
              title: 'Top Songs This Month',
              screenHeight: screenHeight,
              screenWidth: screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
      BuildContext context, {
        required bool isLoading,
        required String? errorMessage,
        required List<Map<String, dynamic>> songs,
        required String title,
        required double screenHeight,
        required double screenWidth,
      }) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text('Error: $errorMessage'));
    }

    if (songs.length < 3) {
      return const Center(
        child: Text('Not enough songs to display the chart.'),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.03, screenWidth * 0.04, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top 3 Grid: Top 1 ở giữa và to hơn, Top 2 và 3 ở hai bên
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Top 2 (bên trái)
                Expanded(
                  child: _buildTopSongCard(
                    context,
                    rank: 2,
                    songData: songs[1],
                    imageSize: screenWidth * 0.18,
                    fontSizeTitle: screenHeight * 0.018,
                    fontSizeArtist: screenHeight * 0.014,
                    fontSizePlays: screenHeight * 0.012,
                    screenWidth: screenWidth,
                  ),
                ),
                // Top 1 (ở giữa, to hơn)
                Expanded(
                  child: _buildTopSongCard(
                    context,
                    rank: 1,
                    songData: songs[0],
                    imageSize: screenWidth * 0.32,
                    fontSizeTitle: screenHeight * 0.025,
                    fontSizeArtist: screenHeight * 0.018,
                    fontSizePlays: screenHeight * 0.014,
                    screenWidth: screenWidth,
                  ),
                ),
                // Top 3 (bên phải)
                Expanded(
                  child: _buildTopSongCard(
                    context,
                    rank: 3,
                    songData: songs[2],
                    imageSize: screenWidth * 0.18,
                    fontSizeTitle: screenHeight * 0.018,
                    fontSizeArtist: screenHeight * 0.014,
                    fontSizePlays: screenHeight * 0.012,
                    screenWidth: screenWidth,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: screenHeight * 0.025,
                color: Theme.of(context).highlightColor,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            // Danh sách bài hát từ vị trí 4 trở đi
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: songs.length - 3,
              itemBuilder: (context, index) {
                final songData = songs[index + 3];
                final song = songData['song'] as Song;
                final artistName = songData['artistName'] as String;
                return SongTile(
                  song: song,
                  artistName: artistName,
                  index: index + 4,
                  isRanking: true,
                  playlist: songs.map((data) => data['song'] as Song).toList(),
                  playlistId: 'chart_${_tabController.index}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSongCard(
      BuildContext context, {
        required int rank,
        required Map<String, dynamic> songData,
        required double imageSize,
        required double fontSizeTitle,
        required double fontSizeArtist,
        required double fontSizePlays,
        required double screenWidth,
      }) {
    final Song song = songData['song'] as Song;
    final String artistName = songData['artistName'] as String;
    final int plays = songData['plays'] as int;

    return Column(
      children: [
        Container(
          width: screenWidth * 0.075,
          height: screenWidth * 0.075,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).highlightColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: imageSize * 0.05),
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: song.coverImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              song.coverImage!,
              fit: BoxFit.cover,
              width: imageSize,
              height: imageSize,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.music_note,
                size: imageSize * 0.5,
                color: Colors.grey[600],
              ),
            ),
          )
              : Center(
            child: Icon(
              Icons.music_note,
              size: imageSize * 0.5,
              color: Colors.grey[600],
            ),
          ),
        ),
        SizedBox(height: imageSize * 0.1),
        Text(
          song.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: fontSizeTitle,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          artistName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: fontSizeArtist,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: imageSize * 0.05),
        Text(
          '${(plays / 1000).toStringAsFixed(1)}K plays',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: fontSizePlays,
            color: Theme.of(context).highlightColor,
          ),
        ),
      ],
    );
  }
}