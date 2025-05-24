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

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<void> login(String email, String password) async {
    final user = await _userService.login(email, password);
    _user = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', user.token!);
    await prefs.setString('user_data', jsonEncode(user.toJson()));

    print('Logged in user role: ${user.role}');
    notifyListeners();
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final user = await _userService.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobile: mobile,
      password: password,
    );
    _user = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', user.token!);
    await prefs.setString('user_data', jsonEncode(user.toJson()));

    print('Registered user role: ${user.role}');
    notifyListeners();
  }

  Future<void> loadUser() async {
    final user = await _userService.getCurrentUser();
    _user = user;
    if (user != null) {
      print('Loaded user role: ${user.role}');
    }
    notifyListeners();
  }

  Future<void> updateUser({
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? avatarImgURL,
  }) async {
    final updatedUser = await _userService.updateUser(
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobile: mobile,
      avatarImgURL: avatarImgURL,
    );
    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

    print('Updated user role: ${updatedUser.role}');
    notifyListeners();
  }

  Future<void> updateAvatar(File avatar) async {
    final updatedUser = await _userService.updateAvatar(avatar);
    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

    notifyListeners();
  }

  Future<void> removeAvatar() async {
    final updatedUser = await _userService.removeAvatar();
    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

    notifyListeners();
  }

  Future<void> changePassword({
    required String oldPassword, // Giữ tham số để tương thích với frontend
    required String newPassword,
  }) async {
    if (_user == null || _user!.email == null) {
      throw Exception('User not logged in');
    }

    // Hiện tại backend không kiểm tra oldPassword, nên không cần gọi login để xác minh
    // Khi backend hỗ trợ kiểm tra oldPassword, bạn có thể thêm lại logic sau:
    /*
    try {
      await _userService.login(_user!.email!, oldPassword);
    } catch (e) {
      throw Exception('Old password is incorrect');
    }
    */

    final updatedUser = await _userService.updateUser(
      password: newPassword,
    );
    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

    notifyListeners();
  }

  Future<void> logout() async {
    await _userService.logout();
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('user_data');

    notifyListeners();
  }
}