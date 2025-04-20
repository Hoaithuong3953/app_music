class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String? password;
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
    this.password, // Không bắt buộc
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
    try {
      // Kiểm tra các trường bắt buộc (bỏ password)
      if (json['_id'] == null ||
          json['firstName'] == null ||
          json['lastName'] == null ||
          json['email'] == null ||
          json['mobile'] == null) {
        throw FormatException('Missing required fields in User JSON');
      }

      // Hàm hỗ trợ để phân tích ngày, hỗ trợ cả ISO 8601 và timestamp
      DateTime? parseDate(dynamic value) {
        if (value == null) return null;
        if (value is String) {
          return DateTime.tryParse(value);
        } else if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return null;
      }

      return User(
        id: json['_id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        mobile: json['mobile'],
        password: json['password'], // Có thể null
        role: json['role'] ?? 'user',
        address: json['address'],
        isBlocked: json['isBlocked'] ?? false,
        refreshToken: json['refreshToken'],
        passwordChangedAt: parseDate(json['passwordChangedAt']),
        passwordResetToken: json['passwordResetToken'],
        passwordResetExpires: parseDate(json['passwordResetExpires']),
        registerToken: json['registerToken'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
    } catch (e) {
      throw FormatException('Error parsing User JSON: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'mobile': mobile,
    'password': password,
    'role': role,
    'address': address,
    'isBlocked': isBlocked,
    'refreshToken': refreshToken,
    'passwordChangedAt': passwordChangedAt?.toIso8601String(),
    'passwordResetToken': passwordResetToken,
    'passwordResetExpires': passwordResetExpires?.toIso8601String(),
    'registerToken': registerToken,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}