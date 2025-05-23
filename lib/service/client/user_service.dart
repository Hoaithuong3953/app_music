import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_client.dart';
import '../../models/user.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  // Đăng nhập người dùng
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiClient.post('user/login', {
        'email': email,
        'password': password,
      });

      if (response['success'] == true) {
        final userData = response['userData'] as Map<String, dynamic>;
        userData['token'] = response['accessToken'] as String;
        final user = User.fromJson(userData);
        return user;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Đăng ký người dùng
  Future<User> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
    required String address,
  }) async {
    try {
      final response = await _apiClient.post('user/register', {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobile': mobile,
        'password': password,
        'address': address,
      });

      if (response['success'] == true) {
        return await login(email, password);
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Lấy thông tin người dùng hiện tại
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

  // Cập nhật thông tin người dùng (bao gồm mật khẩu)
  Future<User> updateUser({
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? password,
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

  // Cập nhật ảnh đại diện người dùng
  Future<User> updateAvatar(File avatar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Tạo multipart request để tải file lên
      var request = http.MultipartRequest('PUT', Uri.parse('${_apiClient.baseUrl}/user/current'));
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(await http.MultipartFile.fromPath('avatar', avatar.path));

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

  // Đăng xuất người dùng
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('user_data');

    try {
      await _apiClient.get('user/logout');
    } catch (e) {
      print('Error calling logout API: $e');
    }
  }
}