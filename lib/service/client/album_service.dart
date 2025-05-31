import 'package:http/http.dart' as http;
import '../../config/api_client.dart';
import '../../models/album.dart';

class AlbumService {
  final ApiClient _apiClient = ApiClient();
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Lấy danh sách tất cả album
  Future<List<Map<String, dynamic>>> getAllAlbums({
    int page = 1,
    int limit = 10,
    String? title,
    String? sort,
    String? fields,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final queryParams = <String, String>{};
        queryParams['page'] = page.toString();
        queryParams['limit'] = limit.toString();
        if (title != null) queryParams['title'] = title;
        if (sort != null) queryParams['sort'] = sort;
        if (fields != null) queryParams['fields'] = fields;

        final response = await _apiClient.get('album/', queryParameters: queryParams);

        if (response['success'] == true) {
          final albumsData = response['data'] as List<dynamic>;
          return albumsData.map((json) {
            return {
              'album': Album.fromJson(json),
              'artistName': json['artist'] != null && json['artist']['title'] != null
                  ? json['artist']['title'].toString()
                  : 'Unknown Artist',
            };
          }).toList();
        } else {
          throw Exception(response['message'] ?? 'Failed to fetch albums');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getAllAlbums, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          print('Error in getAllAlbums: $e');
          return []; // Trả về danh sách rỗng sau khi retry hết
        }
      }
    }
    return [];
  }

  // Lấy thông tin một album theo ID
  Future<Map<String, dynamic>> getAlbumById(String albumId) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.get('album/$albumId');

        if (response['success'] == true) {
          final albumData = response['data'] as Map<String, dynamic>;
          return {
            'album': Album.fromJson(albumData),
            'artistName': albumData['artist'] != null && albumData['artist']['title'] != null
                ? albumData['artist']['title'].toString()
                : 'Unknown Artist',
          };
        } else {
          throw Exception(response['message'] ?? 'Failed to get album');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getAlbumById, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to get album after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to get album after $maxRetries attempts');
  }
} 