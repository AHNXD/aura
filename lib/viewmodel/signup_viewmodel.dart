import 'package:aura/viewmodel/base_viewmodel.dart';
import 'package:flutter/material.dart';

class SignUpViewModel extends BaseViewModel {
  // Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Error messages
  String? _emailError;
  String? _passwordError;

  String? get emailError => _emailError;
  String? get passwordError => _passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Validate email format
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      _emailError = 'Email is required';
      return _emailError;
    }

    // Regular expression for email validation
    const String emailPattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final RegExp regex = RegExp(emailPattern);

    if (!regex.hasMatch(value)) {
      _emailError = 'Please enter a valid email address';
      return _emailError;
    }

    _emailError = null;
    return null;
  }

  /// Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      _passwordError = 'Password is required';
      return _passwordError;
    }

    if (value.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      return _passwordError;
    }

    _passwordError = null;
    return null;
  }

  /// Submit sign up form
  Future<void> signUp() async {
    // Clear previous errors
    _emailError = null;
    _passwordError = null;

    if (formKey.currentState?.validate() ?? false) {
      setLoading(true);

      try {
        // Simulate API call
        await Future.delayed(const Duration(seconds: 2));

        // Get form data
        final email = emailController.text.trim();
        final password = passwordController.text;

        // Here you would typically make an API call to create account
        print('Sign Up - Email: $email, Password length: ${password.length}');

        // Success - navigate to login or home
        // This would be handled by the view

        setLoading(false);
      } catch (e) {
        _emailError = 'Sign up failed. Please try again.';
        setLoading(false);
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  /// Clear form
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    _emailError = null;
    _passwordError = null;
    notifyListeners();
  }
}
