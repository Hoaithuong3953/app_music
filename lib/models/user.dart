import 'package:flutter/material.dart';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String role;
  final String? address;
  final bool isBlocked;
  final String? token;
  final String? avatarImgURL;
  final DateTime? createdAt; // Thêm trường createdAt

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.role,
    this.address,
    this.isBlocked = false,
    this.token,
    this.avatarImgURL,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing User.fromJson: $json'); // Thêm log để debug
    return User(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      address: json['address']?.toString(),
      isBlocked: json['isBlocked'] == true,
      token: json['token']?.toString(),
      avatarImgURL: json['avatarImgURL']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null, // Ánh xạ createdAt
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'role': role,
      'address': address,
      'isBlocked': isBlocked,
      'token': token,
      'avatarImgURL': avatarImgURL,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}