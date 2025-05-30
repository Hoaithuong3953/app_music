import 'package:http/http.dart' as http;
import 'package:music_player_app/models/ranking_song.dart';
import '../../config/api_client.dart';

class RankingService {
  final ApiClient _apiClient = ApiClient();
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Cache dữ liệu xếp hạng
  final Map<String, List<RankingSong>> _cache = {};
  static const Duration cacheDuration = Duration(minutes: 5);
  final Map<String, DateTime> _lastFetchTimes = {};

  Future<List<RankingSong>> getRankings({
    required String type,
    String? genre,
    int limit = 10,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'RANKING:$type-$genre-$limit-$page';
    if (!forceRefresh &&
        _cache.containsKey(cacheKey) &&
        _lastFetchTimes.containsKey(cacheKey) &&
        DateTime.now().difference(_lastFetchTimes[cacheKey]!) < cacheDuration) {
      return _cache[cacheKey]!;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final queryParameters = {
          'type': type,
          if (genre != null) 'genre': genre,
          'limit': limit.toString(),
          'page': page.toString(),
        };
        final response = await _apiClient.get('ranking/realtime', queryParameters: queryParameters);
        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'Failed to fetch rankings');
        }
        if (response['data'] is List<dynamic>) {
          final List<dynamic> data = response['data'] as List<dynamic>;
          final rankings = data.map((json) => RankingSong.fromJson(json)).toList();
          _cache[cacheKey] = rankings;
          _lastFetchTimes[cacheKey] = DateTime.now();
          return rankings;
        } else {
          throw Exception('Invalid data format: data is not a list');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getRankings, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to fetch rankings after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to fetch rankings after $maxRetries attempts');
  }

  Future<List<RankingSong>> getCachedRankings({
    required String type,
    String? genre,
    int limit = 10,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'RANKING_CACHED:$type-$genre-$limit-$page';
    if (!forceRefresh &&
        _cache.containsKey(cacheKey) &&
        _lastFetchTimes.containsKey(cacheKey) &&
        DateTime.now().difference(_lastFetchTimes[cacheKey]!) < cacheDuration) {
      return _cache[cacheKey]!;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final queryParameters = {
          'type': type,
          if (genre != null) 'genre': genre,
          'limit': limit.toString(),
          'page': page.toString(),
        };
        final response = await _apiClient.get('ranking/cached', queryParameters: queryParameters);
        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'Failed to fetch cached rankings');
        }
        if (response['data'] is List<dynamic>) {
          final List<dynamic> data = response['data'] as List<dynamic>;
          final rankings = data.map((json) => RankingSong.fromJson(json)).toList();
          _cache[cacheKey] = rankings;
          _lastFetchTimes[cacheKey] = DateTime.now();
          return rankings;
        } else {
          throw Exception('Invalid data format: data is not a list');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getCachedRankings, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to fetch cached rankings after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to fetch cached rankings after $maxRetries attempts');
  }

  Future<List<RankingSong>> getRankingsWithCache({
    required String type,
    String? genre,
    int limit = 10,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      final cachedRankings = await getCachedRankings(
        type: type,
        genre: genre,
        limit: limit,
        page: page,
        forceRefresh: forceRefresh,
      );
      if (cachedRankings.isNotEmpty) {
        return cachedRankings;
      }
      return await getRankings(
        type: type,
        genre: genre,
        limit: limit,
        page: page,
        forceRefresh: true,
      );
    } catch (e) {
      return await getRankings(
        type: type,
        genre: genre,
        limit: limit,
        page: page,
        forceRefresh: true,
      );
    }
  }
}