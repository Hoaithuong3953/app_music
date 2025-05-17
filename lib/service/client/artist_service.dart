import '../../config/api_client.dart';
import '../../models/artist.dart';

class ArtistService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tất cả nghệ sĩ
  Future<List<Artist>> getAllArtists({
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

      final response = await _apiClient.get('artist/', queryParameters: queryParams);

      if (response['success'] == true) {
        final artistsData = response['data'] as List<dynamic>;
        return artistsData.map((json) => Artist.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get artists');
      }
    } catch (e) {
      throw Exception('Failed to get artists: $e');
    }
  }

  // Lấy thông tin một nghệ sĩ theo ID
  Future<Artist> getArtist(String artistId) async {
    try {
      final response = await _apiClient.get('artist/$artistId');

      if (response['success'] == true) {
        return Artist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get artist');
      }
    } catch (e) {
      throw Exception('Failed to get artist: $e');
    }
  }
}