import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/api_service.dart';
import 'student_dashboard.dart';
import 'driver_dashboard.dart';
import 'admin_dashboard.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  final ApiService _apiService = ApiService();

  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Register the real Firebase device token.
  Future<void> _registerFcmToken() async {
    try {
      debugPrint('FCM DEBUG: Registration function started.');

      final messaging = FirebaseMessaging.instance;

      debugPrint('FCM DEBUG: Requesting notification permission.');

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint(
        'FCM DEBUG: Permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM DEBUG: Permission denied.');
        return;
      }

      debugPrint('FCM DEBUG: Waiting for Firebase Installation ID.');

      final installationIdFuture = messaging.onRegistered.first.timeout(
        const Duration(seconds: 30),
      );

      debugPrint('FCM DEBUG: Calling messaging.register().');

      await messaging.register();

      debugPrint('FCM DEBUG: Firebase registration completed.');

      final installationId = await installationIdFuture;

      debugPrint('FCM DEBUG: Installation ID received.');

      if (installationId.isEmpty) {
        debugPrint('FCM DEBUG: Installation ID is empty.');
        return;
      }

      debugPrint('FCM DEBUG: Sending Installation ID to backend.');

      final result = await _apiService.registerFcmToken(
        installationId: installationId,
        deviceType: 'ANDROID',
      );

      debugPrint('FCM DEBUG: Backend registration response: $result');
    } catch (e, stackTrace) {
      debugPrint('FCM DEBUG ERROR: $e');
      debugPrint('FCM DEBUG STACK TRACE: $stackTrace');
    }
  }

  Future<void> _continue() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        email: _email.text,
        password: _password.text,
      );

      if (!mounted) return;

      final user = response['user'] as Map<String, dynamic>;
      final role = user['role'].toString().toUpperCase();

      late final Widget destination;

      switch (role) {
        case 'STUDENT':
        case 'STAFF':
          // Register FCM only for students and staff.
          await _registerFcmToken();

          if (!mounted) return;

          destination = const StudentDashboard();
          break;

        case 'DRIVER':
          destination = const DriverDashboard();
          break;

        case 'ADMIN':
          destination = const AdminDashboard();
          break;

        default:
          await _apiService.logout();

          throw Exception(
            'Unsupported account role: $role',
          );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => destination,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: Color(0xFF12304A),
                    child: Icon(
                      Icons.directions_bus_filled,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'NITC BUS TRACKING',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track your campus bus. Travel smarter.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _isLoading ? null : _continue,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: _openSignUp,
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Login using your registered NITC account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
