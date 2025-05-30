import 'package:flutter/foundation.dart';
import 'package:music_player_app/models/ranking_song.dart';
import 'package:music_player_app/service/client/ranking_service.dart';

class RankingProvider with ChangeNotifier {
  final RankingService _rankingService = RankingService();

  List<RankingSong> _dailySongs = [];
  List<RankingSong> _weeklySongs = [];
  List<RankingSong> _monthlySongs = [];

  bool _isLoadingDaily = false;
  bool _isLoadingWeekly = false;
  bool _isLoadingMonthly = false;

  String? _errorMessageDaily;
  String? _errorMessageWeekly;
  String? _errorMessageMonthly;

  List<RankingSong> get dailySongs => _dailySongs;
  List<RankingSong> get weeklySongs => _weeklySongs;
  List<RankingSong> get monthlySongs => _monthlySongs;

  bool get isLoadingDaily => _isLoadingDaily;
  bool get isLoadingWeekly => _isLoadingWeekly;
  bool get isLoadingMonthly => _isLoadingMonthly;

  String? get errorMessageDaily => _errorMessageDaily;
  String? get errorMessageWeekly => _errorMessageWeekly;
  String? get errorMessageMonthly => _errorMessageMonthly;

  Future<void> fetchDailySongs({int limit = 20, int page = 1}) async { // Tăng limit lên 20
    _isLoadingDaily = true;
    _errorMessageDaily = null;
    notifyListeners();

    try {
      _dailySongs = await _rankingService.getRankingsWithCache(type: 'daily', limit: limit, page: page);
      print('Fetched ${_dailySongs.length} daily songs');
      _isLoadingDaily = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDaily = false;
      _errorMessageDaily = e.toString();
      print('Error fetching daily songs: $e');
      notifyListeners();
    }
  }

  Future<void> fetchWeeklySongs({int limit = 20, int page = 1}) async { // Tăng limit lên 20
    _isLoadingWeekly = true;
    _errorMessageWeekly = null;
    notifyListeners();

    try {
      _weeklySongs = await _rankingService.getRankingsWithCache(type: 'weekly', limit: limit, page: page);
      print('Fetched ${_weeklySongs.length} weekly songs');
      _isLoadingWeekly = false;
      notifyListeners();
    } catch (e) {
      _isLoadingWeekly = false;
      _errorMessageWeekly = e.toString();
      print('Error fetching weekly songs: $e');
      notifyListeners();
    }
  }

  Future<void> fetchMonthlySongs({int limit = 20, int page = 1}) async { // Tăng limit lên 20
    _isLoadingMonthly = true;
    _errorMessageMonthly = null;
    notifyListeners();

    try {
      _monthlySongs = await _rankingService.getRankingsWithCache(type: 'all', limit: limit, page: page);
      print('Fetched ${_monthlySongs.length} monthly songs');
      _isLoadingMonthly = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMonthly = false;
      _errorMessageMonthly = e.toString();
      print('Error fetching monthly songs: $e');
      notifyListeners();
    }
  }
}