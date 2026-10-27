abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_email.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value, {required bool enforceLength}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (enforceLength && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm password is required';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? title(String? value) {
    if (value == null || value.trim().isEmpty) return 'Title is required';
    if (value.length > 100) return 'Title must be at most 100 characters';
    return null;
  }

  static String? author(String? value) {
    if (value == null || value.trim().isEmpty) return 'Author is required';
    if (value.length > 60) return 'Author must be at most 60 characters';
    return null;
  }

  static String? genre(String? value) =>
      value == null ? 'Please choose a genre' : null;
  static String? status(String? value) =>
      value == null ? 'Please choose a status' : null;

  static String? rating(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 5) {
      return 'Rating must be a whole number from 0 to 5';
    }
    return null;
  }

  static String? notes(String? value) => (value?.length ?? 0) > 300
      ? 'Notes must be at most 300 characters'
      : null;
}
