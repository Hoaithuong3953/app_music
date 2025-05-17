import 'package:http/http.dart' as http;
import '../../config/api_client.dart';
import '../../models/playlist.dart';

class PlaylistService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tất cả playlist
  Future<List<Playlist>> getAllPlaylists({
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
        return playlistsData.map((json) => Playlist.fromJson(json)).toList();
      } else {
        return []; // Trả về danh sách rỗng nếu không có dữ liệu
      }
    } catch (e) {
      print('Error in getAllPlaylists: $e');
      return []; // Trả về danh sách rỗng nếu có lỗi
    }
  }

  // Lấy thông tin một playlist theo ID
  Future<Playlist> getPlaylist(String playlistId) async {
    try {
      final response = await _apiClient.get('playlist/$playlistId');

      if (response['success'] == true) {
        return Playlist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get playlist');
      }
    } catch (e) {
      throw Exception('Failed to get playlist: $e');
    }
  }

  // Tạo playlist mới
  Future<Playlist> createPlaylist({
    required String title,
    required String userId,
    String? coverImagePath, // Đường dẫn file ảnh bìa trên thiết bị
    bool isPublic = true,
    String? token, // Token nếu backend yêu cầu xác thực
  }) async {
    try {
      final fields = <String, String>{
        'title': title,
        'user': userId,
        'isPublic': isPublic.toString(),
      };

      final files = <String, http.MultipartFile>{};
      if (coverImagePath != null) {
        files['cover'] = await http.MultipartFile.fromPath('cover', coverImagePath);
      }

      final response = await _apiClient.post('playlist/', fields, files: files.isNotEmpty ? files : null, token: token);

      if (response['success'] == true) {
        return Playlist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create playlist');
      }
    } catch (e) {
      throw Exception('Failed to create playlist: $e');
    }
  }

  // Cập nhật playlist
  Future<Playlist> updatePlaylist({
    required String playlistId,
    String? title,
    String? coverImagePath, // Đường dẫn file ảnh bìa trên thiết bị
    bool? isPublic,
    String? token, // Token nếu backend yêu cầu xác thực
  }) async {
    try {
      final fields = <String, String>{};
      if (title != null) fields['title'] = title;
      if (isPublic != null) fields['isPublic'] = isPublic.toString();

      final files = <String, http.MultipartFile>{};
      if (coverImagePath != null) {
        files['cover'] = await http.MultipartFile.fromPath('cover', coverImagePath);
      }

      final response = await _apiClient.put(
        'playlist/$playlistId',
        fields,
        files: files.isNotEmpty ? files : null,
        token: token,
      );

      if (response['success'] == true) {
        return Playlist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update playlist');
      }
    } catch (e) {
      throw Exception('Failed to update playlist: $e');
    }
  }

  // Xóa playlist
  Future<void> deletePlaylist({
    required String playlistId,
    String? token, // Token nếu backend yêu cầu xác thực
  }) async {
    try {
      final response = await _apiClient.delete('playlist/$playlistId', token: token);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete playlist');
      }
    } catch (e) {
      throw Exception('Failed to delete playlist: $e');
    }
  }

  // Thêm bài hát vào playlist
  Future<Playlist> addSongsToPlaylist({
    required String playlistId,
    required List<String> songIds,
    String? token, // Token nếu backend yêu cầu xác thực
  }) async {
    try {
      final body = {
        'songs': songIds.join(','), // Chuyển danh sách thành chuỗi phân tách bằng dấu phẩy
      };

      final response = await _apiClient.put('playlist/$playlistId/songs', body, token: token);

      if (response['success'] == true) {
        return Playlist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to add songs to playlist');
      }
    } catch (e) {
      throw Exception('Failed to add songs to playlist: $e');
    }
  }

  // Xóa bài hát khỏi playlist
  Future<Playlist> removeSongsFromPlaylist({
    required String playlistId,
    required List<String> songIds,
    String? token, // Token nếu backend yêu cầu xác thực
  }) async {
    try {
      final body = {
        'songs': songIds.join(','), // Chuyển danh sách thành chuỗi phân tách bằng dấu phẩy
      };

      final response = await _apiClient.delete('playlist/$playlistId/songs', body: body, token: token);

      if (response['success'] == true) {
        return Playlist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to remove songs from playlist');
      }
    } catch (e) {
      throw Exception('Failed to remove songs from playlist: $e');
    }
  }
}