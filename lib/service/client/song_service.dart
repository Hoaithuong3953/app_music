import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../config/api_client.dart';
import '../../models/song.dart';

class SongService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getAllSongs({
    int page = 1,
    int limit = 10,
    String? sort,
    String? fields,
    String? title, // Thêm tham số title để tìm kiếm
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
        if (title != null) queryParams['title'] = title; // Thêm tham số title vào query

        final response = await _apiClient.get('song/', queryParameters: queryParams);

        if (response['success'] == true) {
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
          return [];
        }
      } catch (e) {
        if (e.toString().contains('429') && attempt < maxRetries) {
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
          return Song.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to get song');
        }
      } catch (e) {
        if (e.toString().contains('429') && attempt < maxRetries) {
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
    const delayBetweenRequests = Duration(milliseconds: 500);

    for (int i = 0; i < songIds.length; i++) {
      try {
        final song = await getSong(songIds[i]);
        songs.add(song);
      } catch (e) {
        print('Error fetching song ${songIds[i]}: $e');
        songs.add(Song(
          id: songIds[i],
          title: 'Unknown Song',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
      if (i < songIds.length - 1) {
        await Future.delayed(delayBetweenRequests);
      }
    }

    return songs;
  }
}