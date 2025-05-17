import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:surebuy/pages/customer_home.dart';
import 'package:surebuy/pages/signup_page.dart';
import 'package:surebuy/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  bool _isLoading = false;
  bool isPasswordHidden = true;
  bool _isLocked = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserHasLoggedIn();
    _checkIfBiometricIsEnabled();
  }

  Future<void> _checkIfUserHasLoggedIn() async {
    bool loggedIn = await _authService.isLoggedIn();
    setState(() {});
  }

  Future<void> _checkIfBiometricIsEnabled() async {
    String? isEnabled = await secureStorage.read(key: 'biometric_enabled');

    if (isEnabled != null && isEnabled == 'true') {
      setState(() {
        _isBiometricEnabled = true;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _authenticateWithBiometrics() async {
    bool success = await _authService.authenticateWithBiometrics(
      _showErrorSnackbar,
      _startCountdown,
      (bool isBiometricEnabled, bool isLocked, int countdown) {
        setState(() {
          _isBiometricEnabled = isBiometricEnabled;
          _isLocked = isLocked;
          _countdownSeconds = countdown;
        });
      },
    );

    print("USER BIOMETRIC: $success");
    if (success) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const CustomerHome()));
    }
  }

  // Login function with lock handling
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? result = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });
      print("PRINT: $result");
      switch (result) {
        case 'SUCCESS':
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            String? idToken = await user.getIdToken();
            await secureStorage.write(key: 'firebase_token', value: idToken);
            await secureStorage.write(
                key: 'email', value: _emailController.text);
            print("✅ Firebase token stored for biometric login.");
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHome()),
          );
          break;

        case 'ERROR_USER_NOT_FOUND':
          _showErrorSnackbar('User not found. Please check your email.');
          break;

        case 'ERROR_WRONG_PASSWORD':
          _showErrorSnackbar('Incorrect password. Please try again.');
          break;

        case 'ERROR_TOO_MANY_ATTEMPTS':
        case 'ERROR_ACCOUNT_LOCKED':
          print("⚠️ Account locked. Fetching lock time...");
          _fetchLockTime();
          _showErrorSnackbar(
              'Too many failed attempts. Please try again later.');
          break;

        case 'ERROR_EMAIL_NOT_VERIFIED':
          _showErrorSnackbar('Please verify your email before logging in.');
          break;

        default:
          _showErrorSnackbar('An unknown error occurred. Please try again.');
      }
    }
  }

  void _showResetPasswordDialog() {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email to receive a password reset link.'),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text.trim();
                if (email.isEmpty) {
                  _showErrorSnackbar('Please enter an email.');
                  return;
                }

                try {
                  String response = await _authService.resetPassword(email);

                  if (response == "Sent") {
                    Navigator.pop(context); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Password reset email sent! Check your inbox.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    _showErrorSnackbar("ERROR: $response");
                  }
                } catch (e) {
                  _showErrorSnackbar(
                      'Failed to send reset email. Please try again.');
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  void _fetchLockTime() async {
    print("🛑 Account : ${_emailController.text.trim()}");

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('email', isEqualTo: _emailController.text.trim())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("⚠️ User document not found in Firestore.");
      return;
    }

    DocumentSnapshot userDoc = querySnapshot.docs.first;
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null) {
      print("⚠️ User data is null.");
      return;
    }

    int? lockUntil = userData['lockUntil'];
    print("🛑 Account locked! Unlock in $lockUntil seconds.");

    if (lockUntil != null) {
      DateTime lockTime = DateTime.fromMillisecondsSinceEpoch(lockUntil);
      int remainingSeconds = lockTime.difference(DateTime.now()).inSeconds;

      print("🛑 Account locked! Unlock in $remainingSeconds seconds.");

      if (remainingSeconds > 0) {
        setState(() {
          _isLocked = true;
          _countdownSeconds = remainingSeconds;
        });

        _startCountdown(userDoc.id);
      }
    }
  }

  void _startCountdown(String userId) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdownSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isLocked = false;
        });

        await FirebaseFirestore.instance
            .collection('customers')
            .doc(userId)
            .update({
          'lockUntil': null,
          'failedAttempts': 0,
        }).then((_) {
          print("✅ Lock removed, failedAttempts reset.");
        }).catchError((error) {
          print("❌ Error resetting lock: $error");
        });
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Welcome!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please login to your account',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/surebuy_icon.png',
                            height: 150,
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPasswordHidden = !isPasswordHidden;
                                  });
                                },
                                icon: Icon(
                                  isPasswordHidden
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                            obscureText: isPasswordHidden,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showResetPasswordDialog,
                              child: const Text(
                                'Forgot Password?',
                                style:
                                    TextStyle(color: Colors.blue, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Show countdown message if locked
                          if (_isLocked)
                            Text(
                              'Account locked. Try again in '
                              '$_countdownSeconds seconds.',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 16),
                            ),
                          const SizedBox(height: 8),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLocked ? null : _login,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text('Login'),
                            ),
                          ),

                          const SizedBox(height: 16),
                          // Biometric Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isBiometricEnabled
                                  ? _authenticateWithBiometrics
                                  : null,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Login with Biometrics'),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(fontSize: 18),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SignUpScreen()),
                                  );
                                },
                                child: const Text(
                                  "Signup here",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
