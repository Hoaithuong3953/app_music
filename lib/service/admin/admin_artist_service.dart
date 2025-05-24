import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/artist.dart';
import '../../config/api_client.dart';

class AdminArtistService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tất cả nghệ sĩ
  Future<List<Map<String, dynamic>>> getAllArtists({
    int page = 1,
    int limit = 10,
    String? title,
    String? sort,
    String? fields,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      if (title != null) queryParams['title'] = title;
      if (sort != null) queryParams['sort'] = sort;
      if (fields != null) queryParams['fields'] = fields;

      final response = await _apiClient.get('artist/', queryParameters: queryParams, token: token);

      if (response['success'] == true) {
        final artistsData = response['data'] as List<dynamic>;
        return artistsData.map((json) {
          return {
            'artist': Artist.fromJson(json),
            // Backend không trả về trường liên quan trực tiếp, nên không cần thêm thông tin bổ sung
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getAllArtists: $e');
      return [];
    }
  }

  // Lấy thông tin một nghệ sĩ theo ID
  Future<Map<String, dynamic>> getArtistById(String artistId, {String? token}) async {
    try {
      final response = await _apiClient.get('artist/$artistId', token: token);

      if (response['success'] == true) {
        final artistData = response['data'] as Map<String, dynamic>;
        return {
          'artist': Artist.fromJson(artistData),
        };
      } else {
        throw Exception(response['message'] ?? 'Failed to get artist');
      }
    } catch (e) {
      throw Exception('Failed to get artist: $e');
    }
  }

  // Tạo nghệ sĩ mới
  Future<Artist> createArtist({
    required String title,
    required String avatarPath,
    String? token,
  }) async {
    try {
      final fields = <String, String>{
        'title': title,
      };

      final files = <String, http.MultipartFile>{};
      if (avatarPath.isNotEmpty) {
        files['artist'] = await http.MultipartFile.fromPath('artist', avatarPath);
      }

      final response = await _apiClient.post(
        'artist/',
        fields,
        files: files.isNotEmpty ? files : null,
        token: token,
      );

      if (response['success'] == true) {
        return Artist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create artist');
      }
    } catch (e) {
      throw Exception('Failed to create artist: $e');
    }
  }

  // Cập nhật nghệ sĩ
  Future<Artist> updateArtist({
    required String artistId,
    String? title,
    String? avatarPath,
    String? token,
  }) async {
    try {
      final fields = <String, String>{};
      if (title != null) fields['title'] = title;

      final files = <String, http.MultipartFile>{};
      if (avatarPath != null) {
        files['artist'] = await http.MultipartFile.fromPath('artist', avatarPath);
      }

      final response = await _apiClient.put(
        'artist/$artistId',
        fields,
        files: files.isNotEmpty ? files : null,
        token: token,
      );

      if (response['success'] == true) {
        return Artist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update artist');
      }
    } catch (e) {
      throw Exception('Failed to update artist: $e');
    }
  }

  // Xóa nghệ sĩ
  Future<void> deleteArtist({
    required String artistId,
    String? token,
  }) async {
    try {
      final response = await _apiClient.delete('artist/$artistId', token: token);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete artist');
      }
    } catch (e) {
      throw Exception('Failed to delete artist: $e');
    }
  }

  // Thêm bài hát vào nghệ sĩ
  Future<Artist> addSongsToArtist({
    required String artistId,
    required List<String> songIds,
    String? token,
  }) async {
    try {
      final body = {
        'songs': songIds.join(','),
      };

      final response = await _apiClient.put('artist/$artistId/songs', body, token: token);

      if (response['success'] == true) {
        return Artist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to add songs to artist');
      }
    } catch (e) {
      throw Exception('Failed to add songs to artist: $e');
    }
  }

  // Thêm album vào nghệ sĩ
  Future<Artist> addAlbumsToArtist({
    required String artistId,
    required List<String> albumIds,
    String? token,
  }) async {
    try {
      final body = {
        'albums': albumIds.join(','),
      };

      final response = await _apiClient.put('artist/$artistId/albums', body, token: token);

      if (response['success'] == true) {
        return Artist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to add albums to artist');
      }
    } catch (e) {
      throw Exception('Failed to add albums to artist: $e');
    }
  }

  // Thêm thể loại vào nghệ sĩ
  Future<Artist> addGenreToArtist({
    required String artistId,
    required String genreId,
    String? token,
  }) async {
    try {
      final body = {
        'genre': genreId,
      };

      final response = await _apiClient.put('artist/$artistId/genres', body, token: token);

      if (response['success'] == true) {
        return Artist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to add genre to artist');
      }
    } catch (e) {
      throw Exception('Failed to add genre to artist: $e');
    }
  }

  // Xóa bài hát khỏi nghệ sĩ
  Future<Artist> removeSongsFromArtist({
    required String artistId,
    required List<String> songIds,
    String? token,
  }) async {
    try {
      final body = {
        'songs': songIds.join(','),
      };

      final response = await _apiClient.delete('artist/$artistId/songs', body: body, token: token);

      if (response['success'] == true) {
        return Artist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to remove songs from artist');
      }
    } catch (e) {
      throw Exception('Failed to remove songs from artist: $e');
    }
  }

  // Xóa album khỏi nghệ sĩ
  Future<Artist> removeAlbumsFromArtist({
    required String artistId,
    required List<String> albumIds,
    String? token,
  }) async {
    try {
      final body = {
        'albums': albumIds.join(','),
      };

      final response = await _apiClient.delete('artist/$artistId/albums', body: body, token: token);

      if (response['success'] == true) {
        return Artist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to remove albums from artist');
      }
    } catch (e) {
      throw Exception('Failed to remove albums from artist: $e');
    }
  }

  // Xóa thể loại khỏi nghệ sĩ
  Future<Artist> removeGenreFromArtist({
    required String artistId,
    required String genreId,
    String? token,
  }) async {
    try {
      final body = {
        'genre': genreId,
      };

      final response = await _apiClient.delete('artist/$artistId/genres', body: body, token: token);

      if (response['success'] == true) {
        return Artist.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to remove genre from artist');
      }
    } catch (e) {
      throw Exception('Failed to remove genre from artist: $e');
    }
  }
}