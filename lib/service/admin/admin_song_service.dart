import 'package:http/http.dart' as http;
import '../../config/api_client.dart';
import '../../models/song.dart';

class AdminSongService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách bài hát được một người dùng thích
  Future<List<Map<String, dynamic>>> getSongsLikedByUser({
    required String userId,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'likes': userId,
      };

      final response = await _apiClient.get(
        'song/',
        queryParameters: queryParams,
        token: token,
      );
      print('Get Songs Liked Response: $response'); // Debug

      if (response['success'] == true) {
        final songsData = response['data'] as List<dynamic>;
        return songsData.map((json) {
          final song = Song.fromJson(json);
          return {
            'song': song,
            'artistName': json['artist'] != null &&
                    json['artist'] is Map<String, dynamic> &&
                    json['artist']['title'] != null
                ? json['artist']['title'].toString()
                : 'Không rõ nghệ sĩ',
          };
        }).toList();
      } else {
        print('Lỗi lấy bài hát yêu thích: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Lỗi trong getSongsLikedByUser: $e');
      return [];
    }
  }

  // Lấy thông tin một bài hát theo ID
  Future<Song> getSongById({
    required String songId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.get('song/$songId', token: token);
      print('Get Song By ID Response: $response'); // Debug

      if (response['success'] == true) {
        return Song.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Không thể lấy thông tin bài hát');
      }
    } catch (e) {
      throw Exception('Lỗi lấy thông tin bài hát: $e');
    }
  }

  // Lấy danh sách tất cả bài hát
  Future<Map<String, dynamic>> getAllSongs({
    int page = 1,
    int limit = 100, // Tăng giới hạn để lấy nhiều bài hát hơn
    String? title,
    String? likes,
    String? sort,
    String? fields,
    String? songId,
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      if (title != null) queryParams['title'] = title;
      if (likes != null) queryParams['likes'] = likes;
      if (sort != null) queryParams['sort'] = sort;
      if (fields != null) queryParams['fields'] = fields;

      List<String>? songIds;
      if (songId != null && songId.isNotEmpty) {
        songIds = songId.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
      }

      // Thử truy vấn _id dạng mảng
      if (songIds != null && songIds.isNotEmpty) {
        // Sử dụng toán tử $in: _id[$in]=id1,id2,...
        queryParams['_id[\$in]'] = songIds.join(',');
        print('Calling GET /song/ with params (array query): $queryParams'); // Debug
        try {
          final response = await _apiClient.get(
            'song/',
            queryParameters: queryParams,
            token: token,
          );
          print('Get All Songs Response (array query): $response'); // Debug

          if (response['success'] == true) {
            final songsData = response['data'] as List<dynamic>;
            final songsList = songsData.map((json) {
              final song = Song.fromJson(json);
              return {
                'song': song,
                'artistName': json['artist'] != null &&
                        json['artist'] is Map<String, dynamic> &&
                        json['artist']['title'] != null
                    ? json['artist']['title'].toString()
                    : 'Không rõ nghệ sĩ',
              };
            }).toList();
            return {
              'songs': songsList,
              'totalCount': response['counts']?.toInt() ?? songsList.length,
            };
          } else {
            print('Lỗi lấy bài hát (array query): ${response['message']}');
            throw Exception(response['message'] ?? 'Không thể lấy bài hát');
          }
        } catch (e) {
          print('Lỗi trong truy vấn mảng, chuyển sang lọc phía client: $e');
          // Chuyển sang lấy tất cả bài hát
          queryParams.remove('_id[\$in]');
        }
      }

      // Lấy tất cả bài hát và lọc phía client
      print('Calling GET /song/ with params (fallback): $queryParams'); // Debug
      final response = await _apiClient.get(
        'song/',
        queryParameters: queryParams,
        token: token,
      );
      print('Get All Songs Response (fallback): $response'); // Debug

      if (response['success'] == true) {
        final songsData = response['data'] as List<dynamic>;
        final songsList = songsData.map((json) {
          final song = Song.fromJson(json);
          return {
            'song': song,
            'artistName': json['artist'] != null &&
                    json['artist'] is Map<String, dynamic> &&
                    json['artist']['title'] != null
                ? json['artist']['title'].toString()
                : 'Không rõ nghệ sĩ',
          };
        }).toList();

        // Lọc theo songIds nếu có
        if (songIds != null && songIds.isNotEmpty) {
          final filteredSongs = songsList.where((entry) {
            final song = entry['song'] as Song?;
            if (song == null) {
              print('Cảnh báo: Bỏ qua bài hát null trong entry: $entry');
              return false;
            }
            final songId = song.id;
            return songIds!.contains(songId); // Sử dụng ! vì đã kiểm tra null
          }).toList();
          return {
            'songs': filteredSongs,
            'totalCount': filteredSongs.length,
          };
        }

        return {
          'songs': songsList,
          'totalCount': response['counts']?.toInt() ?? songsList.length,
        };
      } else {
        print('Lỗi lấy bài hát: ${response['message']}');
        return {'songs': [], 'totalCount': 0};
      }
    } catch (e) {
      print('Lỗi trong getAllSongs: $e');
      return {'songs': [], 'totalCount': 0};
    }
  }
}