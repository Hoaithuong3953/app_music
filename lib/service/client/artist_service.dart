import 'package:http/http.dart' as http;
import '../../config/api_client.dart';
import '../../models/artist.dart';

class ArtistService {
  final ApiClient _apiClient = ApiClient();
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Lấy danh sách tất cả nghệ sĩ
  Future<List<Artist>> getAllArtists({
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

        final response = await _apiClient.get('artist/', queryParameters: queryParams);

        if (response['success'] == true) {
          final artistsData = response['data'] as List<dynamic>;
          return artistsData.map((json) => Artist.fromJson(json)).toList();
        } else {
          throw Exception(response['message'] ?? 'Failed to get artists');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getAllArtists, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to get artists after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to get artists after $maxRetries attempts');
  }

  // Lấy thông tin một nghệ sĩ theo ID
  Future<Artist> getArtist(String artistId) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.get('artist/$artistId');

        if (response['success'] == true) {
          return Artist.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to get artist');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getArtist, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to get artist after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to get artist after $maxRetries attempts');
  }
} 