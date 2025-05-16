import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/client/user_service.dart';
import 'dart:convert';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  User? _user;

  User? get user => _user;

  // Đăng nhập người dùng
  Future<void> login(String email, String password) async {
    final user = await _userService.login(email, password);
    _user = user;

    // Lưu token vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', user.token!);
    await prefs.setString('user_data', jsonEncode(user.toJson()));

    notifyListeners();
  }

  // Đăng ký người dùng
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
    required String address,
  }) async {
    final user = await _userService.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobile: mobile,
      password: password,
      address: address,
    );
    _user = user;

    // Lưu token vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', user.token!);
    await prefs.setString('user_data', jsonEncode(user.toJson()));

    notifyListeners();
  }

  // Lấy thông tin người dùng hiện tại
  Future<void> loadUser() async {
    final user = await _userService.getCurrentUser();
    _user = user;
    notifyListeners();
  }

  // Cập nhật thông tin người dùng
  Future<void> updateUser({
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? address,
  }) async {
    final updatedUser = await _userService.updateUser(
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobile: mobile,
      address: address,
    );
    _user = updatedUser;

    // Cập nhật dữ liệu trong SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

    notifyListeners();
  }

  // Thay đổi mật khẩu
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    // Kiểm tra mật khẩu cũ bằng cách thử đăng nhập
    if (_user == null || _user!.email == null) {
      throw Exception('User not logged in');
    }

    try {
      await _userService.login(_user!.email!, oldPassword); // Thử đăng nhập để kiểm tra mật khẩu cũ
    } catch (e) {
      throw Exception('Old password is incorrect');
    }

    // Nếu mật khẩu cũ đúng, tiến hành cập nhật mật khẩu mới
    final updatedUser = await _userService.updateUser(
      password: newPassword,
    );
    _user = updatedUser;

    // Cập nhật dữ liệu trong SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

    notifyListeners();
  }

  // Đăng xuất người dùng
  Future<void> logout() async {
    await _userService.logout();
    _user = null;
    notifyListeners();
  }
}