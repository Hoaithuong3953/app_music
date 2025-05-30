import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_client.dart';
import '../../models/playlist.dart';

class PlaylistService {
  final ApiClient _apiClient = ApiClient();
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Lấy danh sách tất cả playlist
  Future<List<Playlist>> getAllPlaylists({
    int page = 1,
    int limit = 10,
    String? sort,
    String? fields,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
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
          throw Exception(response['message'] ?? 'Failed to fetch playlists');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getAllPlaylists, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        print('Error in getAllPlaylists: $e');
        if (attempt == maxRetries) rethrow;
      }
    }
    return [];
  }

  // Lấy thông tin một playlist theo ID
  Future<Playlist> getPlaylist(String playlistId) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.get('playlist/$playlistId');

        if (response['success'] == true) {
          return Playlist.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to get playlist');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getPlaylist, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to get playlist after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to get playlist after $maxRetries attempts');
  }

  // Tạo playlist mới
  Future<Playlist> createPlaylist({
    required String title,
    required String userId,
    String? coverImagePath,
    bool isPublic = true,
    String? token,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (token == null) {
          throw Exception('No access token found');
        }

        final fields = <String, String>{
          'title': title,
          'user': userId,
        };

        final files = <String, http.MultipartFile>{};
        if (coverImagePath != null) {
          files['cover'] = await http.MultipartFile.fromPath(
            'cover',
            coverImagePath,
            filename: 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }

        final response = await _apiClient.post(
          'playlist/',
          fields,
          files: files.isNotEmpty ? files : null,
          token: token,
        );

        if (response['success'] == true) {
          return Playlist.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to create playlist');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for createPlaylist, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to create playlist after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to create playlist after $maxRetries attempts');
  }

  // Cập nhật playlist
  Future<Playlist> updatePlaylist({
    required String playlistId,
    String? title,
    String? coverImagePath,
    bool? isPublic,
    String? token,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fields = <String, String>{};
        if (title != null) fields['title'] = title;
        if (isPublic != null) fields['isPublic'] = isPublic.toString();

        final files = <String, http.MultipartFile>{};
        if (coverImagePath != null) {
          files['cover'] = await http.MultipartFile.fromPath(
            'cover',
            coverImagePath,
            filename: 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
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
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for updatePlaylist, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to update playlist after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to update playlist after $maxRetries attempts');
  }

  // Xóa playlist
  Future<void> deletePlaylist({
    required String playlistId,
    String? token,
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
    String? token,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final body = {
          'songs': songIds.join(','),
        };

        final response = await _apiClient.put('playlist/$playlistId/songs', body, token: token);

        if (response['success'] == true) {
          return Playlist.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to add songs to playlist');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for addSongsToPlaylist, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to add songs to playlist after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to add songs to playlist after $maxRetries attempts');
  }

  // Xóa bài hát khỏi playlist
  Future<Playlist> removeSongsFromPlaylist({
    required String playlistId,
    required List<String> songIds,
    String? token,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final body = {
          'songs': songIds.join(','),
        };

        final response = await _apiClient.delete('playlist/$playlistId/songs', body: body, token: token);

        if (response['success'] == true) {
          return Playlist.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to remove songs from playlist');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for removeSongsFromPlaylist, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to remove songs from playlist after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to remove songs from playlist after $maxRetries attempts');
  }
} 