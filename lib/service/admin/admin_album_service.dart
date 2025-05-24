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
        return [];
      }
    } catch (e) {
      print('Error in getAllAlbums: $e');
      return [];
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
        throw Exception(response['message'] ?? 'Failed to create album');
      }
    } catch (e) {
      throw Exception('Failed to create album: $e');
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
        throw Exception(response['message'] ?? 'Failed to update album');
      }
    } catch (e) {
      throw Exception('Failed to update album: $e');
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
        throw Exception(response['message'] ?? 'Failed to delete album');
      }
    } catch (e) {
      throw Exception('Failed to delete album: $e');
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
        throw Exception(response['message'] ?? 'Failed to add songs to album');
      }
    } catch (e) {
      throw Exception('Failed to add songs to album: $e');
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
        throw Exception(response['message'] ?? 'Failed to add genre to album');
      }
    } catch (e) {
      throw Exception('Failed to add genre to album: $e');
    }
  }
}