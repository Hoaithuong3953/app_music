import 'package:http/http.dart' as http;
import '../../config/api_client.dart';
import '../../models/song.dart';

class AdminSongService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách bài hát được một người dùng thích
  Future<List<Map<String, dynamic>>> getSongsLikedByUser({
    required String userId,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'likes': userId,
      };

      final response = await _apiClient.get(
        'song/',
        queryParameters: queryParams,
        token: token,
      );
      print('Get Songs Liked Response: $response'); // Debug

      if (response['success'] == true) {
        final songsData = response['data'] as List<dynamic>;
        return songsData.map((json) {
          final song = Song.fromJson(json);
          return {
            'song': song,
            'artistName': json['artist'] != null &&
                    json['artist'] is Map<String, dynamic> &&
                    json['artist']['title'] != null
                ? json['artist']['title'].toString()
                : 'Không rõ nghệ sĩ',
          };
        }).toList();
      } else {
        print('Lỗi lấy bài hát yêu thích: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Lỗi trong getSongsLikedByUser: $e');
      return [];
    }
  }

  // Lấy thông tin một bài hát theo ID
  Future<Song> getSongById({
    required String songId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.get('song/$songId', token: token);
      print('Get Song By ID Response: $response'); // Debug

      if (response['success'] == true) {
        return Song.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Không thể lấy thông tin bài hát');
      }
    } catch (e) {
      throw Exception('Lỗi lấy thông tin bài hát: $e');
    }
  }

  // Lấy danh sách tất cả bài hát
  Future<List<Map<String, dynamic>>> getAllSongs({
    int page = 1,
    int limit = 10,
    String? title,
    String? likes,
    String? sort,
    String? fields,
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      if (title != null) queryParams['title'] = title;
      if (likes != null) queryParams['likes'] = likes;
      if (sort != null) queryParams['sort'] = sort;
      if (fields != null) queryParams['fields'] = fields;

      final response = await _apiClient.get(
        'song/',
        queryParameters: queryParams,
        token: token,
      );
      print('Get All Songs Response: $response'); // Debug

      if (response['success'] == true) {
        final songsData = response['data'] as List<dynamic>;
        return songsData.map((json) {
          final song = Song.fromJson(json);
          return {
            'song': song,
            'artistName': json['artist'] != null &&
                    json['artist'] is Map<String, dynamic> &&
                    json['artist']['title'] != null
                ? json['artist']['title'].toString()
                : 'Không rõ nghệ sĩ',
          };
        }).toList();
      } else {
        print('Lỗi lấy bài hát: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Lỗi trong getAllSongs: $e');
      return [];
    }
  }
}