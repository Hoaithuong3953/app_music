import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/api_client.dart';
import '../../models/user.dart';

class AdminUserService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách người dùng với tìm kiếm và phân trang
  Future<List<Map<String, dynamic>>> getAllUsers({
    int page = 1,
    int limit = 10,
    String? searchQuery,
    String? sort,
    String? fields,
    bool? isPremium, // Thêm tham số lọc Premium
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      if (searchQuery != null) {
        queryParams['email'] = searchQuery;
        queryParams['firstName'] = searchQuery;
        queryParams['lastName'] = searchQuery;
      }
      if (sort != null) queryParams['sort'] = sort;
      if (fields != null) queryParams['fields'] = fields;
      if (isPremium != null) queryParams['isPremium'] = isPremium.toString(); // Thêm query isPremium

      final response = await _apiClient.get('user/', queryParameters: queryParams, token: token);

      if (response['success'] == true) {
        final usersData = response['data'] as List<dynamic>;
        return usersData.map((json) {
          final user = User.fromJson(json);
          return {
            'user': user,
            'fullName': '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
            'email': json['email']?.toString() ?? '',
          };
        }).toList();
      } else {
        print('Lỗi lấy danh sách người dùng: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Lỗi trong getAllUsers: $e');
      return [];
    }
  }

  // Lấy thông tin người dùng theo ID
  Future<Map<String, dynamic>> getUserById(String userId, {required String token}) async {
    try {
      final response = await _apiClient.get('user/?_id=$userId', token: token);

      if (response['success'] == true && response['data'] is List && response['data'].isNotEmpty) {
        final userData = response['data'][0] as Map<String, dynamic>;
        return {
          'user': User.fromJson(userData),
          'fullName': '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
          'email': userData['email']?.toString() ?? '',
        };
      } else {
        throw Exception(response['message'] ?? 'Không thể lấy thông tin người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi lấy thông tin người dùng: $e');
    }
  }

  // Tạo người dùng mới
  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
    String? role = 'user',
    String? address,
    File? avatarFile,
    required String token,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${_apiClient.baseUrl}/user/register'));
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      });

      // Add text fields
      request.fields.addAll({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobile': mobile,
        'password': password,
        'role': role ?? 'user',
        if (address != null) 'address': address,
      });

      // Add avatar file if exists
      if (avatarFile != null) {
        final fileStream = http.ByteStream(avatarFile.openRead());
        final fileLength = await avatarFile.length();
        final multipartFile = http.MultipartFile(
          'avatar',
          fileStream,
          fileLength,
          filename: avatarFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      print('Sending create user request to: ${request.url}');
      print('Request headers: ${request.headers}');
      print('Request fields: ${request.fields}');
      print('Request files: ${request.files}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Tạo người dùng thất bại');
      }
    } catch (e) {
      print('Error in createUser: $e');
      throw Exception('Tạo người dùng thất bại: $e');
    }
  }

  // Cập nhật người dùng
  Future<void> updateUser({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? password,
    String? role,
    bool? isBlocked,
    String? address,
    File? avatarFile,
    required String token,
  }) async {
    try {
      final request = http.MultipartRequest('PUT', Uri.parse('${_apiClient.baseUrl}/user/$userId'));
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      });

      // Add text fields
      if (firstName != null) request.fields['firstName'] = firstName;
      if (lastName != null) request.fields['lastName'] = lastName;
      if (email != null) request.fields['email'] = email;
      if (mobile != null) request.fields['mobile'] = mobile;
      if (password != null) request.fields['password'] = password;
      if (role != null) request.fields['role'] = role;
      if (isBlocked != null) request.fields['isBlocked'] = isBlocked.toString();
      if (address != null) request.fields['address'] = address;

      // Add avatar file if exists
      if (avatarFile != null) {
        final fileStream = http.ByteStream(avatarFile.openRead());
        final fileLength = await avatarFile.length();
        final multipartFile = http.MultipartFile(
          'avatar',
          fileStream,
          fileLength,
          filename: avatarFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      print('Sending update user request to: ${request.url}');
      print('Request headers: ${request.headers}');
      print('Request fields: ${request.fields}');
      print('Request files: ${request.files}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Cập nhật người dùng thất bại');
      }
    } catch (e) {
      print('Error in updateUser: $e');
      throw Exception('Cập nhật người dùng thất bại: $e');
    }
  }

  // Xóa người dùng
  Future<void> deleteUser({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.delete('/user/$userId', token: token);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Xóa người dùng thất bại');
      }
    } catch (e) {
      throw Exception('Xóa người dùng thất bại: $e');
    }
  }

  // Xóa nhiều người dùng
  Future<void> deleteMultipleUsers({
    required List<String> userIds,
    required String token,
  }) async {
    try {
      final response = await _apiClient.delete(
        'user/multiple',
        body: {'userIds': userIds},
        token: token,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Xóa nhiều người dùng thất bại');
      }
    } catch (e) {
      throw Exception('Xóa nhiều người dùng thất bại: $e');
    }
  }
}