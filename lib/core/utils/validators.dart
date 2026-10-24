import '../constants/app_constants.dart';

class AppValidators {
  AppValidators._();

  static String? requiredText(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < AppConstants.minimumPasswordLength) {
      return 'Password must be at least ${AppConstants.minimumPasswordLength} characters.';
    }
    return null;
  }

  static String? phone(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s()-]'), '');
    if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(v)) return 'Enter a valid phone number.';
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value', bool allowZero = false}) {
    final n = double.tryParse((value ?? '').trim());
    if (n == null || !n.isFinite || (allowZero ? n < 0 : n <= 0)) {
      return allowZero ? '$label must be zero or greater.' : '$label must be greater than zero.';
    }
    return null;
  }

  static String? complaint(String? value) {
    final v = (value ?? '').trim();
    if (v.length < AppConstants.minimumComplaintLength) return 'Please enter at least ${AppConstants.minimumComplaintLength} characters.';
    if (v.length > AppConstants.maximumComplaintLength) return 'Please keep the complaint under ${AppConstants.maximumComplaintLength} characters.';
    return null;
  }
}
