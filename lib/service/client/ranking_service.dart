import 'package:music_player_app/models/ranking_song.dart';
import '../../config/api_client.dart';

class RankingService {
  final ApiClient _apiClient = ApiClient();

  Future<List<RankingSong>> getRankings({
    required String type,
    String? genre,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final queryParameters = {
        'type': type,
        if (genre != null) 'genre': genre,
        'limit': limit.toString(),
        'page': page.toString(),
      };

      // Sửa endpoint từ 'ranking' thành 'ranking/realtime'
      final response = await _apiClient.get('ranking/realtime', queryParameters: queryParameters);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to fetch rankings');
      }

      final List<dynamic> data = response['data'] as List<dynamic>;
      return data.map((json) => RankingSong.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch rankings: $e');
    }
  }
}