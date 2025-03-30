import 'dart:convert';
import 'package:http/http.dart' as http;

class GenreService {
  final String baseUrl = "http://10.0.2.2:8080/api/v1/genre";

  Future<List<dynamic>> getGenres() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as List<dynamic>;
      } else {
        throw Exception("Failed to fetch genres");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<Map<String, dynamic>> getGenreById(String gid) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/$gid"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception("Failed to fetch genre");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
