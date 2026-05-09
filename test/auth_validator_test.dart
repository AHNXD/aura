import 'package:aura/services/auth_service.dart';
import 'package:aura/viewmodel/login_viewmodel.dart';
import 'package:aura/viewmodel/signup_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock AuthService for testing
class MockAuthService implements AuthService {
  MockAuthService();

  @override
  Stream<User?> authStateChanges() => Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp({required String email, required String password}) async {}
}

void main() {
  late LoginViewModel loginViewModel;
  late SignUpViewModel signUpViewModel;
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    loginViewModel = LoginViewModel(mockAuthService);
    signUpViewModel = SignUpViewModel(mockAuthService);
  });

  tearDown(() {
    loginViewModel.dispose();
    signUpViewModel.dispose();
  });

  group('Email Validation', () {
    test('should return error for empty email', () {
      final result = loginViewModel.validateEmail('');
      expect(result, 'Email is required');
    });

    test('should return error for null email', () {
      final result = loginViewModel.validateEmail(null);
      expect(result, 'Email is required');
    });

    test('should return error for invalid email format', () {
      final result = loginViewModel.validateEmail('invalid-email');
      expect(result, 'Please enter a valid email address');
    });

    test('should return error for email without domain', () {
      final result = loginViewModel.validateEmail('test@');
      expect(result, 'Please enter a valid email address');
    });

    test('should return error for email without @', () {
      final result = loginViewModel.validateEmail('test.com');
      expect(result, 'Please enter a valid email address');
    });

    test('should return null for valid email', () {
      final result = loginViewModel.validateEmail('test@example.com');
      expect(result, null);
    });

    test('should return null for valid email with subdomain', () {
      final result = loginViewModel.validateEmail('user@sub.example.com');
      expect(result, null);
    });

    test('should return null for valid email with numbers', () {
      final result = loginViewModel.validateEmail('user123@example.com');
      expect(result, null);
    });
  });

  group('Password Validation', () {
    test('should return error for empty password', () {
      final result = loginViewModel.validatePassword('');
      expect(result, 'Password is required');
    });

    test('should return error for null password', () {
      final result = loginViewModel.validatePassword(null);
      expect(result, 'Password is required');
    });

    test('should return error for password shorter than 6 characters', () {
      final result = loginViewModel.validatePassword('12345');
      expect(result, 'Password must be at least 6 characters');
    });

    test('should return null for password with exactly 6 characters', () {
      final result = loginViewModel.validatePassword('123456');
      expect(result, null);
    });

    test('should return null for password longer than 6 characters', () {
      final result = loginViewModel.validatePassword('password123');
      expect(result, null);
    });
  });

  group('SignUpViewModel Validation', () {
    test('should validate email correctly in SignUpViewModel', () {
      final result = signUpViewModel.validateEmail('invalid-email');
      expect(result, 'Please enter a valid email address');

      final validResult = signUpViewModel.validateEmail('valid@example.com');
      expect(validResult, null);
    });

    test('should validate password correctly in SignUpViewModel', () {
      final result = signUpViewModel.validatePassword('short');
      expect(result, 'Password must be at least 6 characters');

      final validResult = signUpViewModel.validatePassword('longpassword');
      expect(validResult, null);
    });
  });

  group('Form Validation Integration', () {
    test('should validate entire form correctly', () {
      // Test individual validations that would be used in form validation
      final emailError = loginViewModel.validateEmail('invalid-email');
      final passwordError = loginViewModel.validatePassword('short');

      expect(emailError, isNotNull);
      expect(passwordError, isNotNull);

      final validEmail = loginViewModel.validateEmail('valid@example.com');
      final validPassword = loginViewModel.validatePassword('longpassword');

      expect(validEmail, null);
      expect(validPassword, null);
    });
  });
}