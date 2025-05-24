import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_client.dart';
import '../../models/genre.dart';

class AdminGenreService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tất cả thể loại
  Future<List<Map<String, dynamic>>> getAllGenres({
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

      final response = await _apiClient.get('genre/', queryParameters: queryParams);

      if (response['success'] == true) {
        final genresData = response['data'] as List<dynamic>;
        return genresData.map((json) {
          final genre = Genre.fromJson(json);
          return {
            'genre': genre,
            'songCount': (json['songs'] as List<dynamic>?)?.length ?? 0,
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getAllGenres: $e');
      return [];
    }
  }

  // Lấy chi tiết một thể loại
  Future<Genre> getGenre(String genreId) async {
    try {
      final response = await _apiClient.get('genre/$genreId');

      if (response['success'] == true) {
        return Genre.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get genre');
      }
    } catch (e) {
      throw Exception('Failed to get genre: $e');
    }
  }

  // Tạo thể loại mới
  Future<Genre> createGenre({
    required String title,
    required String description,
    String? coverImagePath,
    List<String>? songIds,
    String? token,
  }) async {
    try {
      final fields = <String, String>{
        'title': title,
        'description': description,
      };
      if (songIds != null && songIds.isNotEmpty) {
        fields['songs'] = songIds.join(',');
      }

      final files = <String, http.MultipartFile>{};
      if (coverImagePath != null) {
        files['genre'] = await http.MultipartFile.fromPath('genre', coverImagePath);
      }

      final response = await _apiClient.post(
        'genre/',
        fields,
        files: files.isNotEmpty ? files : null,
        token: token,
      );

      if (response['success'] == true) {
        return Genre.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create genre');
      }
    } catch (e) {
      throw Exception('Failed to create genre: $e');
    }
  }

  // Cập nhật thể loại
  Future<Genre> updateGenre({
    required String genreId,
    String? title,
    String? description,
    String? coverImagePath,
    List<String>? songIds,
    String? token,
  }) async {
    try {
      final fields = <String, String>{};
      if (title != null) fields['title'] = title;
      if (description != null) fields['description'] = description;
      if (songIds != null) fields['songs'] = songIds.join(',');

      final files = <String, http.MultipartFile>{};
      if (coverImagePath != null) {
        files['genre'] = await http.MultipartFile.fromPath('genre', coverImagePath);
      }

      final response = await _apiClient.put(
        'genre/$genreId',
        fields,
        files: files.isNotEmpty ? files : null,
        token: token,
      );

      if (response['success'] == true) {
        return Genre.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update genre');
      }
    } catch (e) {
      throw Exception('Failed to update genre: $e');
    }
  }

  // Xóa thể loại
  Future<void> deleteGenre({
    required String genreId,
    String? token,
  }) async {
    try {
      final response = await _apiClient.delete('genre/$genreId', token: token);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete genre');
      }
    } catch (e) {
      throw Exception('Failed to delete genre: $e');
    }
  }

  // Thêm bài hát vào thể loại
  Future<Genre> addSongsToGenre({
    required String genreId,
    required List<String> songIds,
    String? token,
  }) async {
    try {
      final body = {
        'songs': songIds.join(','),
      };

      final response = await _apiClient.post('genre/$genreId', body, token: token);

      if (response['success'] == true) {
        return Genre.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to add songs to genre');
      }
    } catch (e) {
      throw Exception('Failed to add songs to genre: $e');
    }
  }
}