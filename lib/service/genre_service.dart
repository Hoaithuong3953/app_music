import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/genre.dart';

class GenreService {
  final String baseUrl = "http://10.0.2.2:8080/api/v1/genre";

  Future<List<Genre>> getGenres() async {
    try {
      // Lấy access token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('Không có access token');
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("API response (genres): $data"); // Debug
        if (data['success'] == true) {
          return (data['data'] as List).map((json) => Genre.fromJson(json)).toList();
        } else {
          throw Exception("Failed to fetch genres: ${data['message']}");
        }
      } else {
        print("Response body: ${response.body}"); // Debug thêm
        throw Exception("Failed to fetch genres: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<Genre> getGenreById(String gid) async {
    try {
      // Lấy access token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('Không có access token');
      }

      final response = await http.get(
        Uri.parse("$baseUrl/$gid"),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("API response (genre by id): $data"); // Debug
        if (data['success'] == true) {
          return Genre.fromJson(data['data']);
        } else {
          throw Exception("Failed to fetch genre: ${data['message']}");
        }
      } else {
        print("Response body: ${response.body}"); // Debug thêm
        throw Exception("Failed to fetch genre: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}