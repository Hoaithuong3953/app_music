import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    } else {
      return 'http://10.0.2.2:8080/api/v1';
    }
  }

  final http.Client _client = http.Client();
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration timeoutDuration = Duration(seconds: 10);

  // Cache dữ liệu bằng SharedPreferences
  Future<void> _cacheResponse(String key, Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(response));
    await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>?> _getCachedResponse(String key, {Duration cacheDuration = const Duration(minutes: 5)}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(key);
    final timestamp = prefs.getInt('${key}_timestamp') ?? 0;
    if (cachedData != null &&
        DateTime.now().millisecondsSinceEpoch - timestamp < cacheDuration.inMilliseconds) {
      return jsonDecode(cachedData) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    Map<String, http.MultipartFile>? files,
  }) async {
    final url = '$baseUrl/$endpoint';
    final cacheKey = 'POST:$url:${body.toString()}';
    print('Calling POST $url with body: $body');

    // Kiểm tra cache
    final cachedResponse = await _getCachedResponse(cacheKey);
    if (cachedResponse != null) {
      print('Returning cached response for POST $endpoint');
      return cachedResponse;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        late http.Response response;
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

          var streamedResponse = await request.send().timeout(timeoutDuration);
          response = await http.Response.fromStream(streamedResponse);
        } else {
          response = await _client.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          ).timeout(timeoutDuration);
        }

        print('Response from $endpoint: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          final result = jsonDecode(response.body);
          await _cacheResponse(cacheKey, result);
          return result;
        } else if (response.statusCode == 429 && attempt < maxRetries) {
          print('Rate limit hit for POST $endpoint, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        } else {
          throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error in POST $endpoint (attempt $attempt/$maxRetries): $e');
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
        if (e is TimeoutException && attempt < maxRetries) {
          print('Timeout for POST $endpoint, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          if (e.toString().contains('XMLHttpRequest')) {
            throw Exception('CORS error: Backend may not allow requests from this origin.');
          }
          throw Exception('Failed to call API: $endpoint - $e');
        }
      }
    }
    throw Exception('Failed to call API: $endpoint after $maxRetries attempts');
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    Map<String, http.MultipartFile>? files,
  }) async {
    final url = '$baseUrl/$endpoint';
    final cacheKey = 'PUT:$url:${body.toString()}';
    print('Calling PUT $url with body: $body');

    final cachedResponse = await _getCachedResponse(cacheKey);
    if (cachedResponse != null) {
      print('Returning cached response for PUT $endpoint');
      return cachedResponse;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        late http.Response response;
        if (files != null && files.isNotEmpty) {
          var request = http.MultipartRequest('PUT', Uri.parse(url));
          if (token != null) {
            request.headers['Authorization'] = 'Bearer $token';
          }
          body.forEach((key, value) {
            request.fields[key] = value.toString();
          });
          files.forEach((key, file) {
            request.files.add(file);
          });

          var streamedResponse = await request.send().timeout(timeoutDuration);
          response = await http.Response.fromStream(streamedResponse);
        } else {
          response = await _client.put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          ).timeout(timeoutDuration);
        }

        print('Response from $endpoint: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          await _cacheResponse(cacheKey, result);
          return result;
        } else if (response.statusCode == 403) {
          throw Exception('Permission denied: Admin access required');
        } else if (response.statusCode == 429 && attempt < maxRetries) {
          print('Rate limit hit for PUT $endpoint, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        } else {
          throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error in PUT $endpoint (attempt $attempt/$maxRetries): $e');
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
        if (e is TimeoutException && attempt < maxRetries) {
          print('Timeout for PUT $endpoint, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to call API: $endpoint - $e');
        }
      }
    }
    throw Exception('Failed to call API: $endpoint after $maxRetries attempts');
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParameters,
    bool forceRefresh = false,
  }) async {
    final url = '$baseUrl/$endpoint';
    final cacheKey = 'GET:$url:${queryParameters.toString()}';
    print('Calling GET $url');

    if (!forceRefresh) {
      final cachedResponse = await _getCachedResponse(cacheKey);
      if (cachedResponse != null) {
        print('Returning cached response for GET $endpoint');
        return cachedResponse;
      }
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final uri = Uri.parse(url).replace(queryParameters: queryParameters);
        final response = await _client.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ).timeout(timeoutDuration);

        print('Response from $endpoint: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          await _cacheResponse(cacheKey, result);
          return result;
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
            ).timeout(timeoutDuration);
            if (retryResponse.statusCode == 200) {
              final result = jsonDecode(retryResponse.body);
              await _cacheResponse(cacheKey, result);
              return result;
            }
          }
          throw Exception('Failed to authenticate after refresh token');
        } else if (response.statusCode == 429 && attempt < maxRetries) {
          print('Rate limit hit for GET $endpoint, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        } else {
          throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error in GET $endpoint (attempt $attempt/$maxRetries): $e');
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
        if (e is TimeoutException && attempt < maxRetries) {
          print('Timeout for GET $endpoint, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to call API: $endpoint - $e');
        }
      }
    }
    throw Exception('Failed to call API: $endpoint after $maxRetries attempts');
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final url = '$baseUrl/$endpoint';
    print('Calling DELETE $url');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final uri = Uri.parse(url);
        final response = await _client.delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: body != null ? jsonEncode(body) : null,
        ).timeout(timeoutDuration);

        print('Response from $endpoint: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else if (response.statusCode == 403) {
          throw Exception('Permission denied: Admin access required');
        } else if (response.statusCode == 429 && attempt < maxRetries) {
          print('Rate limit hit for DELETE $endpoint, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        } else {
          throw Exception('Failed to call API: $endpoint - ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error in DELETE $endpoint (attempt $attempt/$maxRetries): $e');
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
        if (e is TimeoutException && attempt < maxRetries) {
          print('Timeout for DELETE $endpoint, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to call API: $endpoint - $e');
        }
      }
    }
    throw Exception('Failed to call API: $endpoint after $maxRetries attempts');
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
      ).timeout(timeoutDuration);
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

  Future<void> clearCacheForKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await prefs.remove('${key}_timestamp');
  }
}