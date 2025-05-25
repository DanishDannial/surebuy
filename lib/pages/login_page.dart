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
          // Require biometric authentication after password login
          bool biometricSuccess = await _authService.authenticateWithBiometrics(
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
          if (biometricSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CustomerHome()),
            );
          } else {
            _showErrorSnackbar('Biometric authentication failed.');
            await FirebaseAuth.instance.signOut();
          }
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Reset Password',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email to receive a password reset link.',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    fontFamily: 'SF Pro Text',
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () async {
                  String email = emailController.text.trim();
                  if (email.isEmpty) {
                    _showErrorSnackbar('Please enter an email.');
                    return;
                  }

                  try {
                    String response = await _authService.resetPassword(email);

                    if (response == "Sent") {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Password reset email sent! Check your inbox.',
                            style: TextStyle(fontFamily: 'SF Pro Text'),
                          ),
                          backgroundColor: Colors.green.shade500,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontFamily: 'SF Pro Text'),
      ),
      backgroundColor: Colors.red.shade500,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Logo Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/surebuy.png',
                      height: 120,
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Welcome Text
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SF Pro Display',
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your account',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF Pro Text',
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                fontFamily: 'SF Pro Text',
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.blue.shade400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
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
                          
                          const SizedBox(height: 20),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                fontFamily: 'SF Pro Text',
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.blue.shade400,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPasswordHidden = !isPasswordHidden;
                                  });
                                },
                                icon: Icon(
                                  isPasswordHidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
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

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showResetPasswordDialog,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 14,
                                  fontFamily: 'SF Pro Text',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Lock Warning
                          if (_isLocked)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'Account locked. Try again in $_countdownSeconds seconds.',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                  fontFamily: 'SF Pro Text',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          // Login Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: _isLocked 
                                ? LinearGradient(
                                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                                  )
                                : LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: _isLocked ? null : [
                                BoxShadow(
                                  color: Colors.blue.shade300.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLocked ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'SF Pro Text',
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'SF Pro Text',
                          color: Colors.grey.shade600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpScreen()),
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Text',
                            color: Colors.blue.shade600,
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
      ),
    );
  }
}