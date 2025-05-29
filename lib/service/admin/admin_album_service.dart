import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_client.dart';
import '../../models/album.dart';

class AdminAlbumService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tất cả album
  Future<List<Map<String, dynamic>>> getAllAlbums({
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

      final response = await _apiClient.get('album/', queryParameters: queryParams, token: token);
      print('Get All Albums Response: $response'); // Debug

      if (response['success'] == true) {
        final albumsData = response['data'] as List<dynamic>;
        return albumsData.map((json) {
          return {
            'album': Album.fromJson(json),
            'artistName': json['artist'] != null && json['artist']['title'] != null
                ? json['artist']['title'].toString()
                : 'Không rõ nghệ sĩ',
          };
        }).toList();
      } else {
        print('Lỗi lấy album: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Lỗi trong getAllAlbums: $e');
      return [];
    }
  }

  // Lấy thông tin một album theo ID
  Future<Map<String, dynamic>> getAlbumById(String albumId, {String? token}) async {
    try {
      final response = await _apiClient.get('album/$albumId', token: token);
      print('Get Album By ID Response: $response'); // Debug

      if (response['success'] == true) {
        final albumData = response['data'] as Map<String, dynamic>;
        return {
          'album': Album.fromJson(albumData),
          'artistName': albumData['artist'] != null && albumData['artist']['title'] != null
              ? albumData['artist']['title'].toString()
              : 'Không rõ nghệ sĩ',
        };
      } else {
        throw Exception(response['message'] ?? 'Không thể lấy thông tin album');
      }
    } catch (e) {
      throw Exception('Lỗi lấy album: $e');
    }
  }

  // Tạo album mới
  Future<Album> createAlbum({
    required String title,
    String? artistId,
    String? genreId,
    String? coverImagePath,
    String? token,
  }) async {
    try {
      final fields = <String, String>{
        'title': title,
      };
      if (artistId != null) fields['artist'] = artistId;
      if (genreId != null) fields['genre'] = genreId;

      final files = <String, http.MultipartFile>{};
      if (coverImagePath != null) {
        files['album'] = await http.MultipartFile.fromPath('album', coverImagePath);
      }

      final response = await _apiClient.post(
        'album/',
        fields,
        files: files.isNotEmpty ? files : null,
        token: token,
      );

      if (response['success'] == true) {
        return Album.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Tạo album thất bại');
      }
    } catch (e) {
      throw Exception('Tạo album thất bại: $e');
    }
  }

  // Cập nhật album
  Future<Album> updateAlbum({
    required String albumId,
    String? title,
    String? artistId,
    String? genreId,
    String? coverImagePath,
    List<String>? songIds,
    String? token,
  }) async {
    try {
      final fields = <String, String>{};
      if (title != null) fields['title'] = title;
      if (artistId != null) fields['artist'] = artistId;
      if (genreId != null) fields['genre'] = genreId;
      if (songIds != null) fields['songs'] = songIds.join(',');

      final files = <String, http.MultipartFile>{};
      if (coverImagePath != null) {
        files['album'] = await http.MultipartFile.fromPath('album', coverImagePath);
      }

      final response = await _apiClient.put(
        'album/$albumId',
        fields,
        files: files.isNotEmpty ? files : null,
        token: token,
      );

      if (response['success'] == true) {
        return Album.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Cập nhật album thất bại');
      }
    } catch (e) {
      throw Exception('Cập nhật album thất bại: $e');
    }
  }

  // Xóa album
  Future<void> deleteAlbum({
    required String albumId,
    String? token,
  }) async {
    try {
      final response = await _apiClient.delete('album/$albumId', token: token);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Xóa album thất bại');
      }
    } catch (e) {
      throw Exception('Xóa album thất bại: $e');
    }
  }

  // Thêm bài hát vào album
  Future<Album> addSongsToAlbum({
    required String albumId,
    required List<String> songIds,
    String? token,
  }) async {
    try {
      final body = {
        'songs': songIds.join(','),
      };

      final response = await _apiClient.post('album/add-song/$albumId', body, token: token);

      if (response['success'] == true) {
        return Album.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Thêm bài hát vào album thất bại');
      }
    } catch (e) {
      throw Exception('Thêm bài hát vào album thất bại: $e');
    }
  }

  // Thêm genre vào album
  Future<Album> addGenreToAlbum({
    required String albumId,
    required String genreId,
    String? token,
  }) async {
    try {
      final body = {
        'genre': genreId,
      };

      final response = await _apiClient.post('album/add-genre/$albumId', body, token: token);

      if (response['success'] == true) {
        return Album.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Thêm thể loại vào album thất bại');
      }
    } catch (e) {
      throw Exception('Thêm thể loại vào album thất bại: $e');
    }
  }
}