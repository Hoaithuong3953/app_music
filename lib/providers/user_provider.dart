import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user.dart';
import '../service/client/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  User? _user;

  User? get user => _user;

  // Getter để lấy accessToken từ SharedPreferences
  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  // Đăng nhập người dùng
  Future<void> login(String email, String password) async {
    final user = await _userService.login(email, password);
    _user = user;

    // Lưu token vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', user.token!);
    await prefs.setString('user_data', jsonEncode(user.toJson()));

    print('Logged in user role: ${user.role}'); // Debug role
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

    print('Registered user role: ${user.role}'); // Debug role
    notifyListeners();
  }

  // Lấy thông tin người dùng hiện tại
  Future<void> loadUser() async {
    final user = await _userService.getCurrentUser();
    _user = user;
    if (user != null) {
      print('Loaded user role: ${user.role}'); // Debug role
    }
    notifyListeners();
  }

  // Cập nhật thông tin người dùng
  Future<void> updateUser({
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
  }) async {
    final updatedUser = await _userService.updateUser(
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobile: mobile,
    );
    _user = updatedUser;

    // Cập nhật dữ liệu trong SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

    print('Updated user role: ${updatedUser.role}'); // Debug role
    notifyListeners();
  }

  // Cập nhật ảnh đại diện
  Future<void> updateAvatar(File avatar) async {
    final updatedUser = await _userService.updateAvatar(avatar);
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
    if (_user == null || _user!.email == null) {
      throw Exception('User not logged in');
    }

    try {
      await _userService.login(_user!.email!, oldPassword);
    } catch (e) {
      throw Exception('Old password is incorrect');
    }

    final updatedUser = await _userService.updateUser(
      password: newPassword,
    );
    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

    notifyListeners();
  }

  // Đăng xuất người dùng
  Future<void> logout() async {
    await _userService.logout();
    _user = null;

    // Xóa dữ liệu trong SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('user_data');

    notifyListeners();
  }
}