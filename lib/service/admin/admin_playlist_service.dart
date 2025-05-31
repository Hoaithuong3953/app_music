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
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      if (sort != null) queryParams['sort'] = sort;
      if (fields != null) queryParams['fields'] = fields;

      final response = await _apiClient.get('playlist/', queryParameters: queryParams, token: token);

      if (response['success'] == true) {
        final playlistsData = response['data'] as List<dynamic>;
        return playlistsData.map((json) {
          final playlist = Playlist.fromJson(json);
          String userName = 'Người dùng không xác định';
          String userEmail = '';

          if (json['user'] is Map<String, dynamic>) {
            final user = json['user'] as Map<String, dynamic>;
            userName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
            userEmail = user['email']?.toString() ?? '';
            if (userName.isEmpty) {
              userName = userEmail.isNotEmpty ? userEmail : 'Người dùng không xác định';
            }
          }

          return {
            'playlist': playlist,
            'userName': userName,
            'userEmail': userEmail,
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

  // Lấy thông tin một playlist theo ID
  Future<Map<String, dynamic>> getPlaylistById({
    required String playlistId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.get('playlist/$playlistId', token: token);
      print('Get Playlist By ID Response: $response');

      if (response['success'] == true) {
        final json = response['data'] as Map<String, dynamic>;
        final playlist = Playlist.fromJson(json);
        String userName = 'Người dùng không xác định';

        if (json['user'] is Map<String, dynamic> && json['user']['_id'] != null) {
          // Gọi API để lấy thông tin user đầy đủ
          final userId = json['user']['_id'].toString();
          final userResponse = await _apiClient.get('user/$userId', token: token);
          if (userResponse['success'] == true) {
            final userInfo = userResponse['response'] as Map<String, dynamic>?; // Sửa từ 'data' thành 'response'
            if (userInfo != null) {
              userName = '${userInfo['firstName'] ?? ''} ${userInfo['lastName'] ?? ''}'.trim();
              if (userName.isEmpty) {
                userName = userInfo['email']?.toString() ?? 'Người dùng không xác định';
              }
            } else {
              userName = 'Người dùng không xác định';
            }
          } else {
            userName = json['user']['email']?.toString() ?? 'Người dùng không xác định';
          }
        }

        return {
          'playlist': playlist,
          'userName': userName,
        };
      } else {
        throw Exception(response['message'] ?? 'Không thể lấy thông tin playlist');
      }
    } catch (e) {
      throw Exception('Lỗi lấy thông tin playlist: $e');
    }
  }

  // Xóa playlist theo ID
  Future<void> deletePlaylist({
    required String playlistId,
    required String? token,
  }) async {
    try {
      final response = await _apiClient.delete('playlist/$playlistId', token: token);
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Không thể xóa playlist');
      }
    } catch (e) {
      throw Exception('Lỗi xóa playlist: $e');
    }
  }

  // Thêm bài hát vào playlist
  Future<void> addSongsToPlaylist({
    required String playlistId,
    required List<String> songIds,
    required String? token,
  }) async {
    try {
      final response = await _apiClient.put(
        'playlist/$playlistId',
        {'songs': songIds.join(',')},
        token: token,
      );
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Không thể thêm bài hát vào playlist');
      }
    } catch (e) {
      throw Exception('Lỗi thêm bài hát vào playlist: $e');
    }
  }
}