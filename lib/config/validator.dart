class Validator {
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailPattern.hasMatch(email.trim())) {
      return 'Please enter a valid email (e.g., example@domain.com)';
    }
    return null;
  }

  static String? validateMobile(String? mobile) {
    if (mobile == null || mobile.trim().isEmpty) {
      return 'Mobile number cannot be empty';
    }
    final mobilePattern = RegExp(r'^\d{10,12}$');
    if (!mobilePattern.hasMatch(mobile.trim())) {
      return 'Mobile number must be 10-12 digits';
    }
    return null;
  }

  static String? validateRequiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }
}