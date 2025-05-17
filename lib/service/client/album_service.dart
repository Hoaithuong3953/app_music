import '../../config/api_client.dart';
import '../../models/album.dart';

class AlbumService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tất cả album
  Future<List<Map<String, dynamic>>> getAllAlbums({
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
        return []; // Trả về danh sách rỗng thay vì ném lỗi
      }
    } catch (e) {
      print('Error in getAllAlbums: $e');
      return []; // Trả về danh sách rỗng nếu có lỗi
    }
  }

  // Lấy thông tin một album theo ID
  Future<Map<String, dynamic>> getAlbumById(String albumId) async {
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
      throw Exception('Failed to get album: $e');
    }
  }
}