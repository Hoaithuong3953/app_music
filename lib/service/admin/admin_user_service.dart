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
      final fields = <String, String>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobile': mobile,
        'password': password,
        'role': role ?? 'user',
        if (address != null) 'address': address,
      };

      final files = <String, http.MultipartFile>{};
      if (avatarFile != null) {
        files['avatar'] = await http.MultipartFile.fromPath('avatar', avatarFile.path);
      }

      final response = await _apiClient.post(
        'user/register',
        fields,
        files: files.isNotEmpty ? files : null,
        token: token,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Tạo người dùng thất bại');
      }
    } catch (e) {
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
      final fields = <String, String>{};
      if (firstName != null) fields['firstName'] = firstName;
      if (lastName != null) fields['lastName'] = lastName;
      if (email != null) fields['email'] = email;
      if (mobile != null) fields['mobile'] = mobile;
      if (password != null) fields['password'] = password;
      if (role != null) fields['role'] = role;
      if (isBlocked != null) fields['isBlocked'] = isBlocked.toString();
      if (address != null) fields['address'] = address;

      final files = <String, http.MultipartFile>{};
      if (avatarFile != null) {
        files['avatar'] = await http.MultipartFile.fromPath('avatar', avatarFile.path);
      }

      final response = await _apiClient.put(
        'user/$userId',
        fields,
        files: files.isNotEmpty ? files : null,
        token: token,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Cập nhật người dùng thất bại');
      }
    } catch (e) {
      throw Exception('Cập nhật người dùng thất bại: $e');
    }
  }

  // Xóa người dùng
  Future<void> deleteUser({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.delete('user/$userId', token: token);

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