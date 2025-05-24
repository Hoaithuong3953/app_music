import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_client.dart';
import '../../models/user.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

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

  Future<User> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
  }) async {
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
      throw Exception('Registration failed: $e');
    }
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
    String? avatarImgURL, // Thêm tham số avatarImgURL để hỗ trợ xoá avatar
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
      if (avatarImgURL != null) body['avatarImgURL'] = avatarImgURL; // Gửi avatarImgURL (có thể là null để xoá)

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

      // Thêm email của người dùng vào req.body dưới dạng title
      request.fields['title'] = user.email;

      // Gửi file với filename hợp lệ
      request.files.add(await http.MultipartFile.fromPath(
        'avatar',
        avatar.path,
        filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

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

  // Phương thức mới để xoá avatar
  Future<User> removeAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final body = <String, dynamic>{
        'avatarImgURL': null, // Gửi avatarImgURL là null để xoá
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