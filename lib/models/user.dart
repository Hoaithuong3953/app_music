import 'package:flutter/material.dart';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String password;
  final String role;
  final String? address;
  final bool isBlocked;
  final String? token; // Đổi từ refreshToken thành token
  final String? avatarImgURL;
  final DateTime? passwordChangedAt;
  final String? passwordResetOTP;
  final DateTime? passwordResetExpires;
  final DateTime? lastPasswordResetRequest;
  final int otpAttempts;
  final String? registerToken;
  final bool isPremium;
  final DateTime? premiumExpired;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.password,
    required this.role,
    this.address,
    this.isBlocked = false,
    this.token,
    this.avatarImgURL,
    this.passwordChangedAt,
    this.passwordResetOTP,
    this.passwordResetExpires,
    this.lastPasswordResetRequest,
    this.otpAttempts = 0,
    this.registerToken,
    this.isPremium = false,
    this.premiumExpired,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing User.fromJson: $json');
    return User(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      address: json['address']?.toString(),
      isBlocked: json['isBlocked'] == true,
      token: json['token']?.toString(), // Đổi từ refreshToken thành token
      avatarImgURL: json['avatarImgURL']?.toString(),
      passwordChangedAt: json['passwordChangedAt'] != null ? DateTime.tryParse(json['passwordChangedAt'].toString()) : null,
      passwordResetOTP: json['passwordResetOTP']?.toString(),
      passwordResetExpires: json['passwordResetExpires'] != null ? DateTime.tryParse(json['passwordResetExpires'].toString()) : null,
      lastPasswordResetRequest: json['lastPasswordResetRequest'] != null ? DateTime.tryParse(json['lastPasswordResetRequest'].toString()) : null,
      otpAttempts: json['otpAttempts']?.toInt() ?? 0,
      registerToken: json['registerToken']?.toString(),
      isPremium: json['isPremium'] ?? false,
      premiumExpired: json['premiumExpired'] != null ? DateTime.tryParse(json['premiumExpired'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'password': password,
      'role': role,
      'address': address,
      'isBlocked': isBlocked,
      'token': token, // Đổi từ refreshToken thành token
      'avatarImgURL': avatarImgURL,
      'passwordChangedAt': passwordChangedAt?.toIso8601String(),
      'passwordResetOTP': passwordResetOTP,
      'passwordResetExpires': passwordResetExpires?.toIso8601String(),
      'lastPasswordResetRequest': lastPasswordResetRequest?.toIso8601String(),
      'otpAttempts': otpAttempts,
      'registerToken': registerToken,
      'isPremium': isPremium,
      'premiumExpired': premiumExpired?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}