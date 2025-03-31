import 'dart:convert';
import 'package:http/http.dart' as http;import '../models/genre.dart';

class GenreService {
  final String baseUrl = "http://10.0.2.2:8080/api/v1/genre";

  Future<List<Genre>> getGenres() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List).map((json) => Genre.fromJson(json)).toList();
        } else {
          throw Exception("Failed to fetch genres: ${data['message']}");
        }
      } else {
        throw Exception("Failed to fetch genres: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<Genre> getGenreById(String gid) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/$gid"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Genre.fromJson(data['data']);
        } else {
          throw Exception("Failed to fetch genre: ${data['message']}");
        }
      } else {
        throw Exception("Failed to fetch genre: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}