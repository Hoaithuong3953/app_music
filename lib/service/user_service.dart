import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  final String baseUrl;

  UserService({required this.baseUrl});

  // Đăng ký người dùng
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
    required String address,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/user/register');
    final response = await http.post(
      url,
      body: json.encode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobile': mobile,
        'password': password,
        'address': address,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return responseData;
    } else {
      print('Đăng ký không thành công. Mã lỗi: ${response.statusCode}');
      print('Lý do: ${response.body}');
      throw Exception('Đăng ký không thành công');
    }
  }

  // Đăng nhập người dùng
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/user/login');
    final response = await http.post(
      url,
      body: json.encode({
        'email': email,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('accessToken', responseData['accessToken']);
      return responseData;
    } else {
      print('Đăng nhập không thành công. Mã lỗi: ${response.statusCode}');
      print('Lý do: ${response.body}');
      try {
        final responseData = json.decode(response.body);
        print('Thông báo lỗi từ server: ${responseData['message']}');
      } catch (e) {
        print('Không thể phân tích lỗi từ response body.');
      }
      throw Exception('Đăng nhập không thành công');
    }
  }

  // Lấy thông tin người dùng hiện tại
  Future<User> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      throw Exception('Không có access token');
    }

    final url = Uri.parse('$baseUrl/api/v1/user/current');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Dữ liệu người dùng: $data'); // Log dữ liệu nhận được
      if (data['success'] == true) {
        return User.fromJson(data['response']); // Sửa từ data['data'] thành data['response']
      } else {
        throw Exception('Failed to fetch user: ${data['message']}');
      }
    } else {
      print('Lỗi lấy thông tin người dùng. Mã lỗi: ${response.statusCode}');
      print('Lý do: ${response.body}');
      throw Exception('Lỗi lấy thông tin người dùng');
    }
  }
}