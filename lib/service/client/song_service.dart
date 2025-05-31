import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../config/api_client.dart';
import '../../models/song.dart';

class SongService {
  final ApiClient _apiClient = ApiClient();
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  Future<List<Song>> getSongsByIds(List<String> ids) async {
    try {
      final response = await _apiClient.get('/songs/ids', queryParameters: {'ids': ids.join(',')});
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          return data.map((json) => Song.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching songs by ids: $e');
      return [];
    }
  }

  Future<Song> getSongById(String id) async {
    try {
      final response = await _apiClient.get('/songs/$id');
      if (response['success'] == true) {
        return Song.fromJson(response['data']);
      }
      throw Exception('Failed to load song');
    } catch (e) {
      print('Error fetching song: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllSongs({
    int page = 1,
    int? limit,
    String? title,
    String? likes,
    String? sort,
    String? fields,
  }) async {
    const maxRetries = 5;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final queryParams = <String, String>{};
        queryParams['page'] = page.toString();
        if (limit != null) queryParams['limit'] = limit.toString();
        if (sort != null) queryParams['sort'] = sort;
        if (fields != null) queryParams['fields'] = fields;
        if (title != null) queryParams['title'] = title;
        if (likes != null) queryParams['likes'] = likes;

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
        print('Error in getAllSongs (attempt $attempt/$maxRetries): $e');
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for getAllSongs, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to fetch songs after $maxRetries attempts: $e');
        }
      }
    }

    throw Exception('Failed to fetch songs after $maxRetries attempts');
  }

  Future<Song> getSong(String songId) async {
    const maxRetries = 5;
    const baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.get('song/$songId');

        if (response['success'] == true) {
          final data = response['data'];
          if (data is Map<String, dynamic>) {
            return Song.fromJson(data);
          } else {
            print('Invalid data format for song/$songId: ${data.runtimeType} - $data');
            if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
              print('Fallback: using first element of list as song data');
              return Song.fromJson(data.first as Map<String, dynamic>);
            }
            throw Exception('Invalid data format: data is not a map');
          }
        } else {
          throw Exception(response['message'] ?? 'Failed to get song');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          final delay = baseDelay * attempt;
          print('Rate limit hit for song $songId, retrying ($attempt/$maxRetries) after $delay...');
          await Future.delayed(delay);
          continue;
        }
        print('Error in getSong($songId): $e');
        if (attempt == maxRetries) {
          throw Exception('Mạng yếu hoặc server quá tải, vui lòng thử lại sau.');
        }
        await Future.delayed(baseDelay * attempt);
      }
    }
    throw Exception('Failed to get song after $maxRetries attempts');
  }

  Future<List<Song>> getSongs(List<String> songIds) async {
    List<Song> songs = [];

    final futures = songIds.map((id) async {
      try {
        return await getSong(id);
      } catch (e) {
        print('Error fetching song $id: $e');
        return Song(
          id: id,
          title: 'Unknown Song',
          description: null,
          lyrics: null,
          artist: null,
          album: null,
          genre: const [],
          duration: null,
          slugify: null,
          url: null,
          coverImage: null,
          views: 0,
          dailyViews: 0,
          weeklyViews: 0,
          trendingScore: 0,
          lastReset: DateTime.now(),
          likes: const [],
          dislikes: const [],
          comments: const [],
          isPublic: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }).toList();

    songs = await Future.wait(futures, eagerError: true);

    return songs;
  }

  Future<Song> likeSong(String songId, String token) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.put('song/like/$songId', {}, token: token);

        if (response['success'] == true) {
          return Song.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to like song');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for likeSong, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to like song after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to like song after $maxRetries attempts');
  }

  Future<Song> dislikeSong(String songId, String token) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.put('song/dislike/$songId', {}, token: token);

        if (response['success'] == true) {
          return Song.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to dislike song');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for dislikeSong, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to dislike song after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to dislike song after $maxRetries attempts');
  }

  Future<Song> uploadMusic(String songId, File musicFile, String token) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${_apiClient.baseUrl}/song/$songId/upload'),
        );

        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });

        request.files.add(
          await http.MultipartFile.fromPath(
            'song',
            musicFile.path,
            contentType: MediaType('audio', 'mpeg'),
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return Song.fromJson(responseData['updatedSong']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to upload music');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for uploadMusic, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to upload music after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to upload music after $maxRetries attempts');
  }

  Future<Song> createAndUploadSong({
    required String title,
    required File songFile,
    File? coverFile,
    String? description,
    String? lyrics,
    String? artistId,
    String? albumId,
    List<String>? genreIds,
    required String token,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${_apiClient.baseUrl}/song/'),
        );

        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });

        // Add text fields
        request.fields['title'] = title;
        if (description != null) request.fields['description'] = description;
        if (lyrics != null) request.fields['lyrics'] = lyrics;
        if (artistId != null) request.fields['artist'] = artistId;
        if (albumId != null) request.fields['album'] = albumId;
        if (genreIds != null) request.fields['genre'] = genreIds.join(',');

        // Add files
        request.files.add(
          await http.MultipartFile.fromPath(
            'song',
            songFile.path,
            contentType: MediaType('audio', 'mpeg'),
          ),
        );

        if (coverFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'cover',
              coverFile.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return Song.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create song');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for createAndUploadSong, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to create song after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to create song after $maxRetries attempts');
  }

  Future<Song> updateSong({
    required String songId,
    String? title,
    String? description,
    String? lyrics,
    String? artistId,
    String? albumId,
    List<String>? genreIds,
    File? songFile,
    File? coverFile,
    required String token,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('${_apiClient.baseUrl}/song/$songId'),
        );

        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });

        // Add text fields
        if (title != null) request.fields['title'] = title;
        if (description != null) request.fields['description'] = description;
        if (lyrics != null) request.fields['lyrics'] = lyrics;
        if (artistId != null) request.fields['artist'] = artistId;
        if (albumId != null) request.fields['album'] = albumId;
        if (genreIds != null) request.fields['genre'] = genreIds.join(',');

        // Add files
        if (songFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'song',
              songFile.path,
              contentType: MediaType('audio', 'mpeg'),
            ),
          );
        }

        if (coverFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'cover',
              coverFile.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return Song.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to update song');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for updateSong, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to update song after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to update song after $maxRetries attempts');
  }

  Future<void> deleteSong(String songId, String token) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.delete('song/$songId', token: token);

        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'Failed to delete song');
        }
        return;
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for deleteSong, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to delete song after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to delete song after $maxRetries attempts');
  }
}