import 'package:aura/services/auth_service.dart';
import 'package:aura/theme/app_theme.dart';
import 'package:aura/views/app_root.dart';
import 'package:aura/views/firebase_setup_required_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initializationError;

  try {
    await Firebase.initializeApp();
  } catch (error) {
    initializationError = error;
  }

  runApp(Aura(initializationError: initializationError));
}

class Aura extends StatelessWidget {
  const Aura({super.key, this.initializationError, this.home});

  final Object? initializationError;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home:
          home ??
          (initializationError == null
              ? const AppRoot()
              : FirebaseSetupRequiredScreen(
                  errorDetails: initializationError.toString(),
                )),
    );

    if (home != null || initializationError != null) {
      return app;
    }

    return Provider<AuthService>(create: (_) => AuthService(), child: app);
  }
}
