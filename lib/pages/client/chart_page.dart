import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../models/ranking_song.dart';
import '../../providers/ranking_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/audio_handler_provider.dart';
import '../../providers/playback_provider.dart';
import '../../service/client/song_service.dart';
import '../../widgets/client/song_tile.dart';

class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SongService _songService = SongService();
  final Map<String, Song> _songCache = {};

  List<Song> _dailySongs = [];
  List<Song> _weeklySongs = [];
  List<Song> _monthlySongs = [];
  List<RankingSong> _dailyRanking = [];
  List<RankingSong> _weeklyRanking = [];
  List<RankingSong> _monthlyRanking = [];

  late Future<void> _fetchDataFuture;
  final int _desiredSongCount = 16;
  final int _limitPerPage = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDataFuture = _fetchAllRankingSongs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllRankingSongs() async {
    try {
      final rankingProvider = Provider.of<RankingProvider>(context, listen: false);
      
      int page = 1;
      _dailyRanking = [];
      while (_dailyRanking.length < _desiredSongCount) {
        await rankingProvider.fetchDailySongs(limit: _limitPerPage, page: page);
        _dailyRanking.addAll(rankingProvider.dailySongs);
        if (rankingProvider.dailySongs.length < _limitPerPage) break;
        page++;
      }
      
      page = 1;
      _weeklyRanking = [];
      while (_weeklyRanking.length < _desiredSongCount) {
        await rankingProvider.fetchWeeklySongs(limit: _limitPerPage, page: page);
        _weeklyRanking.addAll(rankingProvider.weeklySongs);
        if (rankingProvider.weeklySongs.length < _limitPerPage) break;
        page++;
      }
      
      page = 1;
      _monthlyRanking = [];
      while (_monthlyRanking.length < _desiredSongCount) {
        await rankingProvider.fetchMonthlySongs(limit: _limitPerPage, page: page);
        _monthlyRanking.addAll(rankingProvider.monthlySongs);
        if (rankingProvider.monthlySongs.length < _limitPerPage) break;
        page++;
      }

      print('Daily Ranking: ${_dailyRanking.map((rs) => rs.songId).toList()}');
      print('Weekly Ranking: ${_weeklyRanking.map((rs) => rs.songId).toList()}');
      print('Monthly Ranking: ${_monthlyRanking.map((rs) => rs.songId).toList()}');

      _dailySongs = await _fetchSongsForRanking(_dailyRanking);
      _weeklySongs = await _fetchSongsForRanking(_weeklyRanking);
      _monthlySongs = await _fetchSongsForRanking(_monthlyRanking);

      print('Daily Songs: ${_dailySongs.map((s) => s.id).toList()}');
      print('Weekly Songs: ${_weeklySongs.map((s) => s.id).toList()}');
      print('Monthly Songs: ${_monthlySongs.map((s) => s.id).toList()}');
    } catch (e) {
      print('Error fetching rankings: $e');
      if (_dailyRanking.isEmpty) {
        _dailyRanking = _createMockRankingSongs();
        _dailySongs = await _fetchSongsForRanking(_dailyRanking);
      }
      if (_weeklyRanking.isEmpty) {
        _weeklyRanking = _createMockRankingSongs();
        _weeklySongs = await _fetchSongsForRanking(_weeklyRanking);
      }
      if (_monthlyRanking.isEmpty) {
        _monthlyRanking = _createMockRankingSongs();
        _monthlySongs = await _fetchSongsForRanking(_monthlyRanking);
      }
    }
  }

  List<RankingSong> _createMockRankingSongs() {
    final List<RankingSong> mockRankings = [];
    for (int i = 0; i < _desiredSongCount; i++) {
      final mockId = 'mock_$i';
      final mockSong = Song(
        id: mockId,
        title: 'Mock Song ${i + 1}',
        description: null,
        lyrics: null,
        artist: 'Mock Artist',
        album: null,
        genre: const [],
        duration: null,
        slugify: null,
        url: null,
        coverImage: 'https://via.placeholder.com/150',
        views: 0,
        dailyViews: 0,
        weeklyViews: 0,
        trendingScore: 0,
        lastReset: DateTime.now(),
        likes: const [],
        dislikes: const [],
        comments: const [],
        isPublic: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _songCache[mockId] = mockSong;
      mockRankings.add(RankingSong(
        songId: mockId,
        song: mockSong,
        artist: 'Mock Artist',
        genre: const [],
        rank: i + 1,
        score: (1000 - i * 100).toDouble(),
      ));
    }
    return mockRankings;
  }

  Future<List<Song>> _fetchSongsForRanking(List<RankingSong> rankingList) async {
    final seen = <String>{};
    final List<String> songIds = [];
    print('Fetching songs for ${rankingList.length} rankings');
    for (final rs in rankingList) {
      if (!seen.contains(rs.songId) && rs.songId.isNotEmpty) {
        seen.add(rs.songId);
        if (!_songCache.containsKey(rs.songId)) {
          songIds.add(rs.songId);
        }
      }
    }
    print('Fetching ${songIds.length} songs with IDs: $songIds');
    try {
      for (final songId in songIds) {
        try {
          final song = await _songService.getSong(songId);
          print('Fetched song with ID: ${song.id}, expected ID: $songId');
          _songCache[songId] = song;
        } catch (e) {
          print('Error fetching song $songId: $e');
          _songCache[songId] = Song(
            id: songId,
            title: 'Unknown Song',
            description: null,
            lyrics: null,
            artist: null,
            album: null,
            genre: const [],
            duration: null,
            slugify: null,
            url: null,
            coverImage: null,
            views: 0,
            dailyViews: 0,
            weeklyViews: 0,
            trendingScore: 0,
            lastReset: DateTime.now(),
            likes: const [],
            dislikes: const [],
            comments: const [],
            isPublic: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }
      final allSongs = <Song>[];
      final seenSongs = <String>{};
      for (final rs in rankingList) {
        if (rs.songId.isNotEmpty) {
          final song = _songCache[rs.songId]!;
          if (!seenSongs.contains(song.id)) {
            seenSongs.add(song.id);
            allSongs.add(song);
          }
        }
      }
      print('Total songs after cache: ${allSongs.length}');

      while (allSongs.length < 3) {
        final mockId = 'mock_${allSongs.length}';
        final mockSong = Song(
          id: mockId,
          title: 'Mock Song ${allSongs.length + 1}',
          description: null,
          lyrics: null,
          artist: 'Mock Artist',
          album: null,
          genre: const [],
          duration: null,
          slugify: null,
          url: null,
          coverImage: 'https://via.placeholder.com/150',
          views: 0,
          dailyViews: 0,
          weeklyViews: 0,
          trendingScore: 0,
          lastReset: DateTime.now(),
          likes: const [],
          dislikes: const [],
          comments: const [],
          isPublic: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        allSongs.add(mockSong);
        _songCache[mockId] = mockSong;
        rankingList.add(RankingSong(
          songId: mockId,
          song: mockSong,
          artist: 'Mock Artist',
          genre: const [],
          rank: allSongs.length,
          score: 0.0,
        ));
      }

      return allSongs;
    } catch (e) {
      print('Error fetching songs: $e');
      final allSongs = <Song>[];
      final seenSongs = <String>{};
      for (final rs in rankingList) {
        if (rs.songId.isNotEmpty) {
          final song = _songCache[rs.songId] ?? Song(
            id: rs.songId,
            title: 'Unknown Song',
            description: null,
            lyrics: null,
            artist: null,
            album: null,
            genre: const [],
            duration: null,
            slugify: null,
            url: null,
            coverImage: null,
            views: 0,
            dailyViews: 0,
            weeklyViews: 0,
            trendingScore: 0,
            lastReset: DateTime.now(),
            likes: const [],
            dislikes: const [],
            comments: const [],
            isPublic: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          if (!seenSongs.contains(song.id)) {
            seenSongs.add(song.id);
            allSongs.add(song);
          }
        }
      }

      while (allSongs.length < 3) {
        final mockId = 'mock_${allSongs.length}';
        final mockSong = Song(
          id: mockId,
          title: 'Mock Song ${allSongs.length + 1}',
          description: null,
          lyrics: null,
          artist: 'Mock Artist',
          album: null,
          genre: const [],
          duration: null,
          slugify: null,
          url: null,
          coverImage: 'https://via.placeholder.com/150',
          views: 0,
          dailyViews: 0,
          weeklyViews: 0,
          trendingScore: 0,
          lastReset: DateTime.now(),
          likes: const [],
          dislikes: const [],
          comments: const [],
          isPublic: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        allSongs.add(mockSong);
        _songCache[mockId] = mockSong;
        rankingList.add(RankingSong(
          songId: mockId,
          song: mockSong,
          artist: 'Mock Artist',
          genre: const [],
          rank: allSongs.length,
          score: 0.0,
        ));
      }

      return allSongs;
    }
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Tắt nút "arrow back"
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
      body: FutureBuilder<void>(
        future: _fetchDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(context, _dailyRanking, _dailySongs, 'Top Songs Today', screenHeight, screenWidth, 0),
              _buildTabContent(context, _weeklyRanking, _weeklySongs, 'Top Songs This Week', screenHeight, screenWidth, 1),
              _buildTabContent(context, _monthlyRanking, _monthlySongs, 'Trending Songs', screenHeight, screenWidth, 2),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabContent(
      BuildContext context,
      List<RankingSong> rankingList,
      List<Song> songList,
      String title,
      double screenHeight,
      double screenWidth,
      int tabIndex) {
    final Map<String, Song> songMap = {};
    final seen = <String>{};
    for (var s in songList) {
      if (!seen.contains(s.id)) {
        seen.add(s.id);
        songMap[s.id] = s;
      }
    }
    print('Song map for $title: $songMap');
    print('Ranking list for $title: ${rankingList.map((rs) => rs.songId).toList()}');

    final List<RankingSong> displayRankingList = rankingList.take(3).toList();
    final List<Song> displaySongList = [];
    final seenRankingIds = <String>{};
    for (var ranking in displayRankingList) {
      if (!seenRankingIds.contains(ranking.songId) && songMap[ranking.songId] != null) {
        seenRankingIds.add(ranking.songId);
        displaySongList.add(songMap[ranking.songId]!);
      }
    }

    if (displaySongList.length < 3) {
      return const Center(
        child: CircularProgressIndicator(),
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
                for (int i in [1, 0, 2])
                  if (displayRankingList.length > i && songMap[displayRankingList[i].songId] != null)
                    Expanded(
                      child: _buildTopSongCard(
                        context,
                        rank: i + 1,
                        songData: displayRankingList[i],
                        song: songMap[displayRankingList[i].songId]!,
                        imageSize: i == 0 ? screenWidth * 0.32 : screenWidth * 0.18,
                        fontSizeTitle: i == 0 ? screenHeight * 0.025 : screenHeight * 0.018,
                        fontSizeArtist: i == 0 ? screenHeight * 0.018 : screenHeight * 0.014,
                        fontSizePlays: i == 0 ? screenHeight * 0.014 : screenHeight * 0.012,
                        screenWidth: screenWidth,
                        songs: songList,
                        tabIndex: tabIndex,
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
              itemCount: rankingList.length - 3,
              itemBuilder: (context, index) {
                final ranking = rankingList[index + 3];
                final song = songMap[ranking.songId];
                if (song == null) {
                  print('Song not found for ranking: ${ranking.songId}');
                  return const SizedBox.shrink();
                }
                return SongTile(
                  song: song,
                  artistName: getArtistName(song.artist),
                  index: index + 4,
                  isRanking: true,
                  playlist: songList,
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
        required RankingSong songData,
        required Song song,
        required double imageSize,
        required double fontSizeTitle,
        required double fontSizeArtist,
        required double fontSizePlays,
        required double screenWidth,
        required List<Song> songs,
        required int tabIndex,
      }) {
    final artistName = getArtistName(song.artist);
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _playSong(
                context,
                song,
                songs,
                'chart_$tabIndex',
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
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
          _formatPlays(plays),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: fontSizePlays,
            color: Theme.of(context).highlightColor,
          ),
        ),
      ],
    );
  }

  String getArtistName(dynamic artist) {
    if (artist == null) return 'Unknown Artist';
    if (artist is String) return artist;
    if (artist is Map && artist['title'] != null) return artist['title'];
    try {
      return artist.title ?? 'Unknown Artist';
    } catch (_) {
      return 'Unknown Artist';
    }
  }

  String _formatPlays(num plays) {
    if (plays >= 1000000) {
      return '${(plays / 1000000).toStringAsFixed(1)}M plays';
    } else if (plays >= 1000) {
      return '${(plays / 1000).toStringAsFixed(1)}K plays';
    } else {
      return '${plays.toStringAsFixed(0)} plays';
    }
  }
}