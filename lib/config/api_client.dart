import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; // Dùng cho Android Emulator
  // static const String baseUrl = 'http://localhost:8080/api/v1'; 
  
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    } else {
      return 'http://10.0.2.2:8080/api/v1';
    }
  }

  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    Map<String, http.MultipartFile>? files,
}) async {
  final url = '$baseUrl/$endpoint';
  print('Calling POST $url with body: $body');
  try {
    if (files != null && files.isNotEmpty) {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      body.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      files.forEach((key, file) {
        request.files.add(file);
      });

      var streamedResponse = await request.send().timeout(Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      print('Response from $endpoint: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
      }
    } else {
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(Duration(seconds: 30));

      print('Response from $endpoint: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
      }
    }
  } catch (e) {
    print('Error in POST $endpoint: $e');
    if (e.toString().contains('XMLHttpRequest')) {
      throw Exception('CORS error: Backend may not allow requests from this origin.');
    }
    throw Exception('Failed to call API: $endpoint - $e');
  }
}

  Future<Map<String, dynamic>> put(
      String endpoint,
      Map<String, dynamic> body, {
        String? token,
        Map<String, http.MultipartFile>? files,
      }) async {
    print('Calling PUT $baseUrl/$endpoint with body: $body');
    try {
      if (files != null && files.isNotEmpty) {
        // Sử dụng multipart request khi có file
        var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/$endpoint'));
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        body.forEach((key, value) {
          request.fields[key] = value.toString();
        });
        files.forEach((key, file) {
          request.files.add(file);
        });

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        print('Response from $endpoint: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else if (response.statusCode == 403) {
          throw Exception('Permission denied: Admin access required');
        } else {
          throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
        }
      } else {
        // Sử dụng JSON request khi không có file
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
      }
    } catch (e) {
      print('Error in PUT $endpoint: $e');
      throw Exception('Failed to call API: $endpoint - $e');
    }
  }

  Future<Map<String, dynamic>> get(
      String endpoint, {
        String? token,
        Map<String, String>? queryParameters,
      }) async {
    print('Calling GET $baseUrl/$endpoint');
    try {
      final uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParameters);
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      print('Response from $endpoint: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied: Admin access required');
      } else if (response.statusCode == 401) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          final retryResponse = await _client.get(
            uri,
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
      print('Error in GET $endpoint: $e');
      throw Exception('Failed to call API: $endpoint - $e');
    }
  }

  Future<Map<String, dynamic>> delete(
      String endpoint, {
        Map<String, dynamic>? body,
        String? token,
      }) async {
    print('Calling DELETE $baseUrl/$endpoint');
    try {
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await _client.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body != null ? jsonEncode(body) : null,
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
      print('Error in DELETE $endpoint: $e');
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
      print('Error refreshing token: $e');
      return null;
    }
  }
}