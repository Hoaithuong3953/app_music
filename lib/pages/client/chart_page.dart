import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../models/ranking_song.dart';
import '../../providers/ranking_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/audio_handler_provider.dart';
import '../../providers/playback_provider.dart';
import '../../service/client/song_service.dart'; // Thêm SongService
import '../../widgets/client/song_tile.dart';

class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;
  final SongService _songService = SongService(); // Khởi tạo SongService

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final rankingProvider = Provider.of<RankingProvider>(context, listen: false);
      rankingProvider.fetchDailySongs();
      rankingProvider.fetchWeeklySongs();
      rankingProvider.fetchMonthlySongs();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _playSong(BuildContext context, Song song, List<Song> playlist, String playlistId) async {
    try {
      if (song.url == null || song.url!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot play song: URL is missing')),
        );
        return;
      }

      final songProvider = Provider.of<SongProvider>(context, listen: false);
      final audioHandlerProvider = Provider.of<AudioHandlerProvider>(context, listen: false);
      final playbackProvider = Provider.of<PlaybackProvider>(context, listen: false);

      songProvider.setPlaylist(playlist, playlistId: playlistId);
      songProvider.setCurrentSong(song);

      if (songProvider.currentSong?.id == song.id && playbackProvider.isPlaying) {
        await audioHandlerProvider.playPause();
      } else {
        await audioHandlerProvider.playSong(song);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing song: $e')),
      );
    }
  }

  // Hàm mới để lấy thông tin bài hát nếu song chưa được populate
  Future<Song> _fetchSong(String songId) async {
    try {
      return await _songService.getSong(songId);
    } catch (e) {
      if (!mounted) throw Exception('Context not mounted');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching song: $e')),
      );
      return Song(
        id: songId,
        title: 'Unknown Song',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // lastReset: DateTime.now(),
      );
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
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            Consumer<RankingProvider>(
              builder: (context, rankingProvider, child) {
                return _buildTabContent(
                  context,
                  isLoading: rankingProvider.isLoadingDaily,
                  errorMessage: rankingProvider.errorMessageDaily,
                  songs: rankingProvider.dailySongs,
                  title: 'Top Songs Today',
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                  tabIndex: 0,
                );
              },
            ),
            Consumer<RankingProvider>(
              builder: (context, rankingProvider, child) {
                return _buildTabContent(
                  context,
                  isLoading: rankingProvider.isLoadingWeekly,
                  errorMessage: rankingProvider.errorMessageWeekly,
                  songs: rankingProvider.weeklySongs,
                  title: 'Top Songs This Week',
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                  tabIndex: 1,
                );
              },
            ),
            Consumer<RankingProvider>(
              builder: (context, rankingProvider, child) {
                return _buildTabContent(
                  context,
                  isLoading: rankingProvider.isLoadingMonthly,
                  errorMessage: rankingProvider.errorMessageMonthly,
                  songs: rankingProvider.monthlySongs,
                  title: 'Trending Songs',
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                  tabIndex: 2,
                );
              },
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
        required List<RankingSong> songs,
        required String title,
        required double screenHeight,
        required double screenWidth,
        required int tabIndex,
      }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FutureBuilder<Song>(
                    future: songs[1].song != null ? Future.value(songs[1].song) : _fetchSong(songs[1].songId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final song = snapshot.data!;
                      return _buildTopSongCard(
                        context,
                        rank: 2,
                        songData: songs[1],
                        song: song,
                        imageSize: screenWidth * 0.18,
                        fontSizeTitle: screenHeight * 0.018,
                        fontSizeArtist: screenHeight * 0.014,
                        fontSizePlays: screenHeight * 0.012,
                        screenWidth: screenWidth,
                        songs: songs,
                        tabIndex: tabIndex,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Song>(
                    future: songs[0].song != null ? Future.value(songs[0].song) : _fetchSong(songs[0].songId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final song = snapshot.data!;
                      return _buildTopSongCard(
                        context,
                        rank: 1,
                        songData: songs[0],
                        song: song,
                        imageSize: screenWidth * 0.32,
                        fontSizeTitle: screenHeight * 0.025,
                        fontSizeArtist: screenHeight * 0.018,
                        fontSizePlays: screenHeight * 0.014,
                        screenWidth: screenWidth,
                        songs: songs,
                        tabIndex: tabIndex,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Song>(
                    future: songs[2].song != null ? Future.value(songs[2].song) : _fetchSong(songs[2].songId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final song = snapshot.data!;
                      return _buildTopSongCard(
                        context,
                        rank: 3,
                        songData: songs[2],
                        song: song,
                        imageSize: screenWidth * 0.18,
                        fontSizeTitle: screenHeight * 0.018,
                        fontSizeArtist: screenHeight * 0.014,
                        fontSizePlays: screenHeight * 0.012,
                        screenWidth: screenWidth,
                        songs: songs,
                        tabIndex: tabIndex,
                      );
                    },
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: songs.length - 3,
              itemBuilder: (context, index) {
                final songData = songs[index + 3];
                return FutureBuilder<Song>(
                  future: songData.song != null ? Future.value(songData.song) : _fetchSong(songData.songId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final song = snapshot.data!;
                    return SongTile(
                      song: song,
                      artistName: songData.artist,
                      index: index + 4,
                      isRanking: true,
                      playlist: songs.map((data) => data.song ?? Song(
                        id: data.songId,
                        title: 'Unknown Song',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        // lastReset: DateTime.now(),
                      )).toList(),
                      playlistId: 'chart_${_tabController.index}',
                    );
                  },
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
        required RankingSong songData,
        required Song song, // Thêm tham số song để đảm bảo luôn có Song đầy đủ
        required double imageSize,
        required double fontSizeTitle,
        required double fontSizeArtist,
        required double fontSizePlays,
        required double screenWidth,
        required List<RankingSong> songs,
        required int tabIndex,
      }) {
    final artistName = songData.artist;
    final plays = songData.score;

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
        GestureDetector(
          onTap: () {
            _playSong(
              context,
              song,
              songs.map((data) => data.song ?? Song(
                id: data.songId,
                title: 'Unknown Song',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                // lastReset: DateTime.now(),
              )).toList(),
              'chart_$tabIndex',
            );
          },
          child: Container(
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