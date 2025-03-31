import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/album.dart';

class AlbumService {
  final String baseUrl = "http://10.0.2.2:8080";

  Future<List<Album>> fetchAlbums() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/album'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API response: $data"); // Debug
        if (data['success'] == true) {
          return (data['data'] as List).map((json) => Album.fromJson(json)).toList();
        } else {
          print('API error: ${data['message']}');
          return [];
        }
      } else {
        print('Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print("Lỗi khi lấy album: $e");
      return [];
    }
  }
}