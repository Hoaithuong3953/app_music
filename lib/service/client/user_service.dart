import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_client.dart';
import '../../models/user.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  Future<User> login(String email, String password) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.post('user/login', {
          'email': email,
          'password': password,
        });

        if (response['success'] == true) {
          final userData = response['userData'] as Map<String, dynamic>;
          userData['token'] = response['accessToken'] as String;
          final user = User.fromJson(userData);
          
          // Lưu token vào SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', response['accessToken']);
          await prefs.setString('user_data', jsonEncode(userData));
          
          return user;
        } else {
          throw Exception(response['message'] ?? 'Login failed');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for login, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Login failed after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Login failed after $maxRetries attempts');
  }

  Future<User> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.post('user/register', {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'mobile': mobile,
          'password': password,
        });

        if (response['success'] == true) {
          return await login(email, password);
        } else {
          throw Exception(response['message'] ?? 'Registration failed');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for register, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Registration failed after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Registration failed after $maxRetries attempts');
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        print('No access token found');
        return null;
      }

      final response = await _apiClient.get('user/current', token: accessToken);

      if (response['success'] == true) {
        final userData = response['response'] as Map<String, dynamic>;
        userData['token'] = accessToken;
        return User.fromJson(userData);
      } else {
        print('Failed to fetch user: ${response['message']}');
        await prefs.remove('accessToken');
        await prefs.remove('user_data');
        return null;
      }
    } catch (e) {
      print('Error in getCurrentUser: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('user_data');
      return null;
    }
  }

  Future<User> updateUser({
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? password,
    String? avatarImgURL,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (email != null) body['email'] = email;
      if (mobile != null) body['mobile'] = mobile;
      if (password != null) body['password'] = password;
      if (avatarImgURL != null) body['avatarImgURL'] = avatarImgURL;

      final response = await _apiClient.put('user/current', body, token: accessToken);

      if (response['success'] == true) {
        final userData = response['updateUser'] as Map<String, dynamic>;
        userData['token'] = accessToken;
        return User.fromJson(userData);
      } else {
        throw Exception(response['message'] ?? 'Update user failed');
      }
    } catch (e) {
      throw Exception('Update user failed: $e');
    }
  }

  Future<User> updateAvatar(File avatar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final user = await getCurrentUser();

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      if (user == null || user.email == null) {
        throw Exception('User email not found');
      }

      var request = http.MultipartRequest('PUT', Uri.parse('${_apiClient.baseUrl}/user/current'));
      request.headers['Authorization'] = 'Bearer $accessToken';

      request.fields['title'] = user.email;

      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          avatar.path,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final userData = jsonResponse['updateUser'] as Map<String, dynamic>;
          userData['token'] = accessToken;
          return User.fromJson(userData);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Update avatar failed');
        }
      } else {
        throw Exception('Update avatar failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update avatar failed: $e');
    }
  }

  Future<User> removeAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final body = <String, dynamic>{
        'avatarImgURL': null,
      };

      final response = await _apiClient.put('user/current', body, token: accessToken);

      if (response['success'] == true) {
        final userData = response['updateUser'] as Map<String, dynamic>;
        userData['token'] = accessToken;
        return User.fromJson(userData);
      } else {
        throw Exception(response['message'] ?? 'Remove avatar failed');
      }
    } catch (e) {
      throw Exception('Remove avatar failed: $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.post('user/forgot-password', {
          'email': email,
        });

        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'Failed to send OTP');
        }
        return;
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for forgotPassword, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to send OTP after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to send OTP after $maxRetries attempts');
  }

  Future<void> resetPassword(String password, String otp) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.post('user/reset-password', {
          'password': password,
          'otp': otp,
        });

        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'Failed to reset password');
        }
        return;
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for resetPassword, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to reset password after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to reset password after $maxRetries attempts');
  }

  Future<String> refreshAccessToken() async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _apiClient.get('user/refresh-token');

        if (response['success'] == true) {
          final newToken = response['newAccessToken'] as String;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', newToken);
          return newToken;
        } else {
          throw Exception(response['message'] ?? 'Failed to refresh token');
        }
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for refreshAccessToken, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          throw Exception('Failed to refresh token after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Failed to refresh token after $maxRetries attempts');
  }

  Future<String> upgradeToPremium(String duration) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('accessToken');

        if (accessToken == null) {
          throw Exception('No access token found');
        }

        // Xóa cache trước khi gọi API
        final url = '${_apiClient.baseUrl}/user/upgrade-to-premium';
        final cacheKey = 'POST:$url:{duration: $duration}';
        await prefs.remove(cacheKey);
        await prefs.remove('${cacheKey}_timestamp');

        print('Calling upgrade-to-premium API with duration: $duration');
        final response = await _apiClient.post(
          'user/upgrade-to-premium',
          {'duration': duration},
          token: accessToken,
        );

        print('Response from upgrade-to-premium: $response');
        
        if (response is Map<String, dynamic> && 
            response['success'] == true && 
            response['paymentUrl'] != null && 
            response['paymentUrl'].toString().isNotEmpty) {
          return response['paymentUrl'] as String;
        } else {
          throw Exception(response is Map ? 
            (response['message'] ?? 'Không nhận được link thanh toán premium') : 
            'Không nhận được link thanh toán premium');
        }
      } catch (e) {
        print('Error in upgradeToPremium attempt $attempt: $e');
        if (attempt == maxRetries) rethrow;
        await Future.delayed(retryDelay);
      }
    }
    throw Exception('Failed to upgrade to premium after $maxRetries attempts');
  }

  Future<void> logout() async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('accessToken');

        if (accessToken != null) {
          await _apiClient.get('user/logout', token: accessToken);
        }

        await prefs.remove('accessToken');
        await prefs.remove('user_data');
        return;
      } catch (e) {
        if (e is http.ClientException && e.message.contains('429') && attempt < maxRetries) {
          print('Rate limit hit for logout, retrying ($attempt/$maxRetries)...');
          await Future.delayed(retryDelay);
          continue;
        }
        if (attempt == maxRetries) {
          print('Error calling logout API: $e');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('accessToken');
          await prefs.remove('user_data');
        }
      }
    }
  }

  Future<User> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await _apiClient.put(
        'user/change-password',
        {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
        token: accessToken,
      );

      if (response['success'] == true) {
        final userData = response['user'] as Map<String, dynamic>;
        userData['token'] = accessToken;
        return User.fromJson(userData);
      } else {
        throw Exception(response['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }
} 