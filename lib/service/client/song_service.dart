import 'package:http/http.dart' as http;
import '../../config/api_client.dart';
import '../../models/song.dart';

class SongService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tất cả bài hát với tìm kiếm theo title
  Future<List<Map<String, dynamic>>> getAllSongs({
    int page = 1,
    int limit = 10,
    String? title,
    String? sort,
    String? fields,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      if (title != null) queryParams['title'] = title;
      if (sort != null) queryParams['sort'] = sort;
      if (fields != null) queryParams['fields'] = fields;

      final response = await _apiClient.get('song/', queryParameters: queryParams);

      if (response['success'] == true) {
        final songsData = response['data'] as List<dynamic>;
        return songsData.map((json) {
          final song = Song.fromJson(json);
          return {
            'song': song,
            'artistName': song.artist ?? 'Unknown Artist',
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getAllSongs: $e');
      return [];
    }
  }

  // Lấy thông tin một bài hát theo ID
  Future<Song> getSong(String songId) async {
    try {
      final response = await _apiClient.get('song/$songId');

      if (response['success'] == true) {
        return Song.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get song');
      }
    } catch (e) {
      throw Exception('Failed to get song: $e');
    }
  }
}