class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String password; // Mật khẩu đã mã hóa
  final String role;
  final String? address;
  final bool isBlocked;
  final String? refreshToken;
  final DateTime? passwordChangedAt;
  final String? passwordResetToken;
  final DateTime? passwordResetExpires;
  final String? registerToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.password,
    this.role = 'user',
    this.address,
    this.isBlocked = false,
    this.refreshToken,
    this.passwordChangedAt,
    this.passwordResetToken,
    this.passwordResetExpires,
    this.registerToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      mobile: json['mobile'],
      password: json['password'],
      role: json['role'] ?? 'user',
      address: json['address'],
      isBlocked: json['isBlocked'] ?? false,
      refreshToken: json['refreshToken'],
      passwordChangedAt: json['passwordChangedAt'] != null
          ? DateTime.parse(json['passwordChangedAt'])
          : null,
      passwordResetToken: json['passwordResetToken'],
      passwordResetExpires: json['passwordResetExpires'] != null
          ? DateTime.parse(json['passwordResetExpires'])
          : null,
      registerToken: json['registerToken'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}