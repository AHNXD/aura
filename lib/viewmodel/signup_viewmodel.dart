import 'package:aura/viewmodel/base_viewmodel.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignUpViewModel extends BaseViewModel {
  SignUpViewModel(this._authService);

  final AuthService _authService;

  // Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Error messages
  String? _emailError;
  String? _passwordError;
  String? _authError;

  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get authError => _authError;

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
  Future<bool> signUp() async {
    // Clear previous errors
    _emailError = null;
    _passwordError = null;
    _authError = null;

    if (formKey.currentState?.validate() ?? false) {
      setLoading(true);

      try {
        await _authService.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        return true;
      } on AuthFailure catch (error) {
        _authError = error.message;
        notifyListeners();
        return false;
      } catch (_) {
        _authError = 'Sign up failed. Please try again.';
        notifyListeners();
        return false;
      } finally {
        setLoading(false);
      }
    } else {
      notifyListeners();
      return false;
    }
  }

  /// Clear form
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    _emailError = null;
    _passwordError = null;
    _authError = null;
    notifyListeners();
  }
}
