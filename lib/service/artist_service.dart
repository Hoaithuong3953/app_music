import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artist.dart';

class ArtistService {
  final String baseUrl = "http://10.0.2.2:8080";

  Future<List<Artist>> fetchArtists() async {
    try {
      // Lấy access token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        print("Không có access token được lưu trữ");
        throw Exception('Không có access token');
      }

      // Gửi yêu cầu GET đến endpoint /api/v1/artist
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/artist'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API response (artists): $data"); // Debug dữ liệu trả về

        if (data['success'] == true) {
          // Kiểm tra xem data['data'] là String hay List
          if (data['data'] is String) {
            print("Không có artist nào: ${data['data']}");
            return [];
          }
          return (data['data'] as List).map((json) => Artist.fromJson(json)).toList();
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
      print("Lỗi khi lấy danh sách artist: $e");
      return [];
    }
  }

  // Nếu bạn muốn lấy một artist cụ thể theo ID
  Future<Artist?> getArtistById(String aid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        print("Không có access token được lưu trữ");
        throw Exception('Không có access token');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/artist/$aid'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API response (artist by ID): $data"); // Debug dữ liệu

        if (data['success'] == true) {
          return Artist.fromJson(data['data']);
        } else {
          print('API error: ${data['message']}');
          return null;
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print("Lỗi khi lấy artist theo ID: $e");
      return null;
    }
  }
}