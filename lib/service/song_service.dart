import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class SongService {
  final String baseUrl = "http://10.0.2.2:8080";

  Future<List<Song>> fetchSongs() async {
    try {
      // Lấy access token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        print("Không có access token được lưu trữ");
        throw Exception('Không có access token');
      }

      // Thêm header Authorization vào yêu cầu
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/song'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

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
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print("Lỗi khi lấy bài hát: $e");
      return [];
    }
  }
}