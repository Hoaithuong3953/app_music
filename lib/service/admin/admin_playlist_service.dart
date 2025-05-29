import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_client.dart';
import '../../models/playlist.dart';

class AdminPlaylistService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách playlist cho admin, bao gồm thông tin user để tìm kiếm
  Future<List<Map<String, dynamic>>> getAllPlaylistsForAdmin({
    int page = 1,
    int limit = 10,
    String? sort,
    String? fields,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      if (sort != null) queryParams['sort'] = sort;
      if (fields != null) queryParams['fields'] = fields;

      final response = await _apiClient.get('playlist/', queryParameters: queryParams);

      if (response['success'] == true) {
        final playlistsData = response['data'] as List<dynamic>;
        return playlistsData.map((json) {
          final playlist = Playlist.fromJson(json);
          return {
            'playlist': playlist,
            'userName': json['user'] is Map<String, dynamic>
                ? '${json['user']['firstName'] ?? ''} ${json['user']['lastName'] ?? ''}'.trim()
                : 'Unknown User',
            'userEmail': json['user'] is Map<String, dynamic> ? json['user']['email']?.toString() ?? '' : '',
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getAllPlaylistsForAdmin: $e');
      return [];
    }
  }
}