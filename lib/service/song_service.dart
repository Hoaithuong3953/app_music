import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/song.dart';

class SongService {
  final String baseUrl = "http://10.0.2.2:8080";

  Future<List<Song>> fetchSongs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/song'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API response: $data"); // In dữ liệu để debug
        if (data['success'] == true) {
          return (data['data'] as List).map((json) => Song.fromJson(json)).toList();
        } else {
          print('API error: ${data['message']}');
          return [];
        }
      } else {
        print('Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print("Lỗi khi lấy bài hát: $e");
      return [];
    }
  }
}