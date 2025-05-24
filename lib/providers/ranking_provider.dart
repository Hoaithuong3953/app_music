import 'package:flutter/material.dart';
import 'package:music_player_app/models/ranking_song.dart';
import 'package:music_player_app/service/client/ranking_service.dart';

class RankingProvider with ChangeNotifier {
  final RankingService _rankingService = RankingService();

  // Danh sách bài hát cho từng loại xếp hạng
  List<RankingSong> _dailySongs = [];
  List<RankingSong> _weeklySongs = [];
  List<RankingSong> _monthlySongs = [];

  // Trạng thái loading
  bool _isLoadingDaily = false;
  bool _isLoadingWeekly = false;
  bool _isLoadingMonthly = false;

  // Thông báo lỗi
  String? _errorMessageDaily;
  String? _errorMessageWeekly;
  String? _errorMessageMonthly;

  // Getters
  List<RankingSong> get dailySongs => _dailySongs;
  List<RankingSong> get weeklySongs => _weeklySongs;
  List<RankingSong> get monthlySongs => _monthlySongs;

  bool get isLoadingDaily => _isLoadingDaily;
  bool get isLoadingWeekly => _isLoadingWeekly;
  bool get isLoadingMonthly => _isLoadingMonthly;

  String? get errorMessageDaily => _errorMessageDaily;
  String? get errorMessageWeekly => _errorMessageWeekly;
  String? get errorMessageMonthly => _errorMessageMonthly;

  Future<void> fetchDailySongs({int limit = 10, int page = 1}) async {
    _isLoadingDaily = true;
    _errorMessageDaily = null;
    notifyListeners();

    try {
      _dailySongs = await _rankingService.getRankings(type: 'daily', limit: limit, page: page);
      _isLoadingDaily = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDaily = false;
      _errorMessageDaily = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchWeeklySongs({int limit = 10, int page = 1}) async {
    _isLoadingWeekly = true;
    _errorMessageWeekly = null;
    notifyListeners();

    try {
      _weeklySongs = await _rankingService.getRankings(type: 'weekly', limit: limit, page: page);
      _isLoadingWeekly = false;
      notifyListeners();
    } catch (e) {
      _isLoadingWeekly = false;
      _errorMessageWeekly = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchMonthlySongs({int limit = 10, int page = 1}) async {
    _isLoadingMonthly = true;
    _errorMessageMonthly = null;
    notifyListeners();

    try {
      _monthlySongs = await _rankingService.getRankings(type: 'all', limit: limit, page: page);
      _isLoadingMonthly = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMonthly = false;
      _errorMessageMonthly = e.toString();
      notifyListeners();
    }
  }
}