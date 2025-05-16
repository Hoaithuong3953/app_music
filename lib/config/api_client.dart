import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; // Dùng cho Android Emulator
  // Nếu chạy trên thiết bị thật, thay bằng IP của máy: 'http://192.168.1.x:8080/api/v1'
  // Nếu backend đã deploy, thay bằng URL thực tế: 'https://your-backend-api.com/api/v1'
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    print('Calling POST $baseUrl/$endpoint with body: $body'); // Thêm log để debug
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      print('Response from $endpoint: ${response.statusCode} - ${response.body}'); // Thêm log
      if (response.statusCode == 200 || response.statusCode == 201) { // Thêm mã 201
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: Admin access required');
      } else {
        throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in POST $endpoint: $e'); // Thêm log
      throw Exception('Failed to call API: $endpoint - $e');
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body, {String? token}) async {
    print('Calling PUT $baseUrl/$endpoint with body: $body');
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      print('Response from $endpoint: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: Admin access required');
      } else {
        throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in PUT $endpoint: $e');
      throw Exception('Failed to call API: $endpoint - $e');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    print('Calling GET $baseUrl/$endpoint'); // Thêm log
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      print('Response from $endpoint: ${response.statusCode} - ${response.body}'); // Thêm log
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: Admin access required');
      } else if (response.statusCode == 401) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          final retryResponse = await _client.get(
            Uri.parse('$baseUrl/$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
          );
          if (retryResponse.statusCode == 200) {
            return jsonDecode(retryResponse.body);
          }
        }
        throw Exception('Failed to authenticate after refresh token');
      } else {
        throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in GET $endpoint: $e'); // Thêm log
      throw Exception('Failed to call API: $endpoint - $e');
    }
  }

  Future<String?> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return null;

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/user/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['newAccessToken'] != null) {
          final newAccessToken = data['newAccessToken'];
          await prefs.setString('access_token', newAccessToken);
          return newAccessToken;
        }
      }
      return null;
    } catch (e) {
      print('Error refreshing token: $e'); // Thêm log
      return null;
    }
  }
}