import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../../config/api_client.dart';
import '../../models/genre.dart';
import '../../models/song.dart';

class AdminGenreService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tất cả thể loại
  Future<List<Map<String, dynamic>>> getAllGenres({
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

      final response = await _apiClient.get('genre/', queryParameters: queryParams, token: token);
      print('Get All Genres Response: $response'); // Debug

      if (response['success'] == true) {
        final genresData = response['data'] as List<dynamic>;
        return genresData.map((json) {
          final genre = Genre.fromJson(json);
          return {
            'genre': genre,
            'songCount': genre.songs.length,
          };
        }).toList();
      } else {
        throw Exception(response['message'] ?? 'Không thể lấy danh sách thể loại');
      }
    } catch (e) {
      throw Exception('Lỗi lấy danh sách thể loại: $e');
    }
  }

  // Lấy chi tiết một thể loại cùng danh sách bài hát
  Future<Map<String, dynamic>> getGenreDetails(String genreId, {String? token}) async {
    try {
      final response = await _apiClient.get('genre/$genreId', token: token);
      print('Get Genre By ID Response: $response'); // Debug

      if (response['success'] == true) {
        final genre = Genre.fromJson(response['data']);
        return {
          'genre': genre,
          'songs': genre.songs,
        };
      } else {
        throw Exception(response['message'] ?? 'Không thể lấy thông tin thể loại');
      }
    } catch (e) {
      throw Exception('Lỗi lấy thể loại: $e');
    }
  }

  // Lấy danh sách nghệ sĩ thuộc một thể loại (truy vấn gián tiếp qua Song)
  Future<List<Map<String, dynamic>>> getArtistsInGenre({
    required String genreId,
    required String token,
  }) async {
    try {
      // Lấy chi tiết thể loại để có danh sách bài hát
      final genreData = await getGenreDetails(genreId, token: token);
      final genre = genreData['genre'] as Genre;
      final songIds = genre.songs.map((song) => song['id']).toList();

      if (songIds.isEmpty) {
        return [];
      }

      // Tạo query parameters với _id là mảng
      final queryParams = <String, String>{};
      songIds.asMap().forEach((index, id) {
        queryParams['_id[$index]'] = id;
      });

      // Lấy danh sách bài hát để truy xuất artist
      final response = await _apiClient.get(
        'song/',
        queryParameters: queryParams,
        token: token,
      );
      print('Get Songs Response: $response'); // Debug

      if (response['success'] == true) {
        final songsData = response['data'] as List<dynamic>;
        // Lấy danh sách artist từ các bài hát
        final artists = songsData.map((json) {
          return {
            'id': json['artist']?['_id']?.toString() ?? '',
            'title': json['artist']?['title']?.toString() ?? 'Unknown Artist',
          };
        }).toList();

        // Loại bỏ trùng lặp artist
        final uniqueArtists = <String, Map<String, dynamic>>{};
        for (var artist in artists) {
          final artistId = artist['id'] as String;
          if (artistId.isNotEmpty) {
            uniqueArtists[artistId] = artist;
          }
        }

        return uniqueArtists.values.toList();
      } else {
        throw Exception(response['message'] ?? 'Không thể lấy danh sách nghệ sĩ');
      }
    } catch (e) {
      throw Exception('Lỗi lấy danh sách nghệ sĩ: $e');
    }
  }

  // Tạo thể loại mới
  Future<Genre> createGenre({
    required String title,
    required String description,
    PlatformFile? coverImageFile, // Sử dụng PlatformFile thay vì coverImagePath
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
      if (coverImageFile != null) {
        if (kIsWeb) {
          // Trên web, sử dụng bytes
          if (coverImageFile.bytes != null) {
            files['genre'] = http.MultipartFile.fromBytes(
              'genre',
              coverImageFile.bytes!,
              filename: coverImageFile.name,
            );
          }
        } else {
          // Trên mobile, sử dụng path
          if (coverImageFile.path != null) {
            files['genre'] = await http.MultipartFile.fromPath(
              'genre',
              coverImageFile.path!,
            );
          }
        }
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
        throw Exception(response['message'] ?? 'Tạo thể loại thất bại');
      }
    } catch (e) {
      throw Exception('Tạo thể loại thất bại: $e');
    }
  }

  // Cập nhật thể loại
  Future<Genre> updateGenre({
    required String genreId,
    String? title,
    String? description,
    PlatformFile? coverImageFile, // Sử dụng PlatformFile thay vì coverImagePath
    List<String>? songIds,
    String? token,
  }) async {
    try {
      final fields = <String, String>{};
      if (title != null) fields['title'] = title;
      if (description != null) fields['description'] = description;
      if (songIds != null) fields['songs'] = songIds.join(',');

      final files = <String, http.MultipartFile>{};
      if (coverImageFile != null) {
        if (kIsWeb) {
          // Trên web, sử dụng bytes
          if (coverImageFile.bytes != null) {
            files['genre'] = http.MultipartFile.fromBytes(
              'genre',
              coverImageFile.bytes!,
              filename: coverImageFile.name,
            );
          }
        } else {
          // Trên mobile, sử dụng path
          if (coverImageFile.path != null) {
            files['genre'] = await http.MultipartFile.fromPath(
              'genre',
              coverImageFile.path!,
            );
          }
        }
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
        throw Exception(response['message'] ?? 'Cập nhật thể loại thất bại');
      }
    } catch (e) {
      throw Exception('Cập nhật thể loại thất bại: $e');
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
        throw Exception(response['message'] ?? 'Xóa thể loại thất bại');
      }
    } catch (e) {
      throw Exception('Xóa thể loại thất bại: $e');
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

      final response = await _apiClient.post('genre/$genreId/songs', body, token: token);

      if (response['success'] == true) {
        return Genre.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Thêm bài hát vào thể loại thất bại');
      }
    } catch (e) {
      throw Exception('Thêm bài hát vào thể loại thất bại: $e');
    }
  }

  // Xóa bài hát khỏi thể loại
  Future<Genre> removeSongFromGenre({
    required String genreId,
    required String songId,
    String? token,
  }) async {
    try {
      final body = {
        'songs': songId,
      };

      final response = await _apiClient.post('genre/$genreId/songs/remove', body, token: token);

      if (response['success'] == true) {
        return Genre.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Xóa bài hát khỏi thể loại thất bại');
      }
    } catch (e) {
      throw Exception('Xóa bài hát khỏi thể loại thất bại: $e');
    }
  }
}