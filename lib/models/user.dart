import 'package:flutter/material.dart';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String role;
  final bool isBlocked;
  final String? token;
  final String? avatarImgURL;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.role,
    this.isBlocked = false,
    this.token,
    this.avatarImgURL,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing User.fromJson: $json');
    return User(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isBlocked: json['isBlocked'] == true,
      token: json['token']?.toString(),
      avatarImgURL: json['avatarImgURL']?.toString(),
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
      'isBlocked': isBlocked,
      'token': token,
      'avatarImgURL': avatarImgURL,
    };
  }
}