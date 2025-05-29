import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../config/api_client.dart';
import '../../models/song.dart';

class SongService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách tất cả bài hát với tìm kiếm theo title hoặc likes
  Future<List<Map<String, dynamic>>> getAllSongs({
    int page = 1,
    int limit = 10,
    String? title,
    String? likes,
    String? sort,
    String? fields,
  }) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final queryParams = <String, String>{};
        queryParams['page'] = page.toString();
        queryParams['limit'] = limit.toString();
        if (sort != null) queryParams['sort'] = sort;
        if (fields != null) queryParams['fields'] = fields;
        if (title != null) queryParams['title'] = title;
        if (likes != null) queryParams['likes'] = likes; // Thêm tham số likes

        final response = await _apiClient.get('song/', queryParameters: queryParams);

        if (response['success'] == true) {
          if (response['data'] is List<dynamic>) {
            final songsData = response['data'] as List<dynamic>;
            return songsData.map((json) {
              return {
                'song': Song.fromJson(json),
                'artistName': json['artist'] != null
                    ? (json['artist']['title']?.toString() ?? 'Unknown Artist')
                    : 'Unknown Artist',
              };
            }).toList();
          } else {
            throw Exception('Invalid data format: data is not a list');
          }
        } else {
          throw Exception(response['message'] ?? 'Failed to fetch songs');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getAllSongs, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        print('Error in getAllSongs: $e');
        throw Exception('Failed to fetch songs: $e');
      }
    }

    throw Exception('Failed to fetch songs after $maxRetries attempts');
  }

  Future<Song> getSong(String songId) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.get('song/$songId');

        if (response['success'] == true) {
          if (response['data'] is Map<String, dynamic>) {
            return Song.fromJson(response['data']);
          } else {
            throw Exception('Invalid data format: data is not a map');
          }
        } else {
          throw Exception(response['message'] ?? 'Failed to get song');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for song $songId, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        throw Exception('Failed to get song: $e');
      }
    }

    throw Exception('Failed to get song after $maxRetries attempts');
  }

  Future<List<Song>> getSongs(List<String> songIds) async {
    List<Song> songs = [];

    // Sử dụng Future.wait để gọi đồng thời, nhưng vẫn giữ cơ chế retry trong getSong
    final futures = songIds.map((id) async {
      try {
        return await getSong(id);
      } catch (e) {
        print('Error fetching song $id: $e');
        return Song(
          id: id,
          title: 'Unknown Song',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }).toList();

    songs = await Future.wait(futures, eagerError: true);

    return songs;
  }
}