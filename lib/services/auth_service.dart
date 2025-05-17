import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Function to handle user signup
  Future<UserCredential?> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      // Create user in Firebase Authentication with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Save additional user data (name, role) in Firestore
      await _firestore
          .collection('customers')
          .doc(userCredential.user!.uid)
          .set({
        'email': email.trim(),
        'name': name.trim(),
        'phone': phone.trim(), // Save phone number
        'address': address.trim(), // Save address
        'status': 'Pending',
        'failedAttempts': 0,
        'lockUntil': null
      });

      return userCredential; // Success: no error message
    } catch (e) {
      return null; // Error: return the exception message
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('customers')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 'ERROR_USER_NOT_FOUND';
      }

      DocumentSnapshot userDoc = querySnapshot.docs.first;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userId = userDoc.id;

      if (await isUserLocked(userData)) {
        return 'ERROR_ACCOUNT_LOCKED';
      }

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        print("PRINTDATA: ${userCredential.user}");

        if (!userCredential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          return 'ERROR_EMAIL_NOT_VERIFIED';
        }

        User? user = userCredential.user;

        if (user != null && user.emailVerified) {
          await _firestore.collection('customers').doc(userId).update({
            'status': 'Verified',
          });
        }
        await resetFailedAttempts(userId);

        return 'SUCCESS';
      } on FirebaseAuthException catch (e) {
        print("ERROR: ${e.code}");

        if (e.code == 'invalid-credential') {
          await handleFailedAttempt(userId);
          return 'ERROR_WRONG_PASSWORD';
        } else if (e.code == 'user-not-found') {
          return 'ERROR_USER_NOT_FOUND';
        } else if (e.code == 'too-many-requests') {
          return 'ERROR_TOO_MANY_ATTEMPTS';
        } else {
          return 'ERROR_UNKNOWN';
        }
      }
    } catch (e) {
      return 'An unknown error occurred. Please try again later. ${e.toString()}';
    }
  }

  Future<String?> getFirebaseToken({ required String userId}) async {
    try {
      print("BearerToken userId:  $userId");

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      print("BearerToken user:  ${user}");

      // Ensure user is signed in and matches the requested UID
      if (user == null || user.uid != userId) {
        print("User not signed in or incorrect UID");
        return null;
      }

      // Fetch ID Token
      String? idToken = await user.getIdToken();

      print("ID Token for $userId: $idToken");
      return idToken;
    } catch (e) {
      print("Error fetching token: $e");
      return null;
    }
  }

  Future<void> resetFailedAttempts(String userId) async {
    DocumentReference userRef = _firestore.collection('customers').doc(userId);
    await userRef.update({
      'failedAttempts': 0,
      'lockUntil': null,
    });
  }

  Future<String> handleFailedAttempt(String userId) async {
    print("Updating failedAttempts for user ID: $userId");
    DocumentReference userRef = _firestore.collection('customers').doc(userId);
    DocumentSnapshot userDoc = await userRef.get();

    if (!userDoc.exists) return 'User not found. Please sign up first.';

    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    int failedAttempts = userData?['failedAttempts'] ?? 0;
    failedAttempts++;

    if (failedAttempts >= 3) {
      DateTime lockTime = DateTime.now().add(const Duration(seconds: 60));
      int lockUntilTimestamp = lockTime.millisecondsSinceEpoch;
      await userRef.update({
        'failedAttempts': failedAttempts,
        'lockUntil': lockUntilTimestamp,
      });
      return 'Account locked due to multiple failed attempts. Try again in 1 minute.';
    } else {
      await userRef.update({'failedAttempts': failedAttempts});
      return 'Incorrect password. You have ${3 - failedAttempts} attempts left.';
    }
  }

  Future<bool> isUserLocked(Map<String, dynamic> userData) async {
    int? lockUntil = userData['lockUntil'];
    if (lockUntil == null) return false;

    DateTime lockTime = DateTime.fromMillisecondsSinceEpoch(lockUntil);
    return DateTime.now().isBefore(lockTime);
  }

  // Function to handle user logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> isLoggedIn() async {
    User? user = _auth.currentUser;
    print("USER: $user");
    if (user == null) return false;

    DocumentSnapshot userDoc =
        await _firestore.collection('customers').doc(user.uid).get();
    print("USER: ${userDoc.data()}");

    if (!userDoc.exists) return false;

    if (await isUserLocked(userDoc.data() as Map<String, dynamic>)) {
      await logout();
      return false;
    }

    return true;
  }

  // Function to handle password reset
  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return "Sent";
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> authenticateWithBiometrics(Function showErrorSnackbar,
      Function startCountdown, Function updateUI) async {
    bool isAuthenticated = await _localAuth.authenticate(
      localizedReason: 'Use fingerprint/Face ID to log in',
      options: const AuthenticationOptions(
        biometricOnly: true,
        useErrorDialogs: true,
        stickyAuth: true,
      ),
    );
    print("USER isAuthenticated: $isAuthenticated");

    if (!isAuthenticated) {
      await handleFailedBiometricAttempt(
          showErrorSnackbar, startCountdown, updateUI);
      return false;
    }

    String? savedEmail = await secureStorage.read(key: 'email');
    print("USER savedEmail: $savedEmail");

    if (savedEmail == null) return false;

    QuerySnapshot querySnapshot = await _firestore
        .collection('customers')
        .where('email', isEqualTo: savedEmail.trim())
        .limit(1)
        .get();

    print("USER querySnapshot: ${querySnapshot.docs}");

    if (querySnapshot.docs.isEmpty) return false;

    DocumentSnapshot userDoc = querySnapshot.docs.first;
    String userId = userDoc.id;

    await resetFailedAttempts(userId);

    return true;
  }

  Future<void> handleFailedBiometricAttempt(Function showErrorSnackbar,
      Function startCountdown, Function updateUI) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    QuerySnapshot querySnapshot = await _firestore
        .collection('customers')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    DocumentSnapshot userDoc = querySnapshot.docs.first;
    String userId = userDoc.id;

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    int failedAttempts = (userData['failedAttempts'] ?? 0) + 1;
    const int lockDuration = 60 * 1000; // Lock for 1 minute

    if (failedAttempts >= 3) {
      int lockUntil = DateTime.now().millisecondsSinceEpoch + lockDuration;

      await _firestore.collection('customers').doc(userId).update({
        'lockUntil': lockUntil,
        'failedAttempts': 0,
      });

      showErrorSnackbar(
          "Too many failed attempts. Account locked for 1 minute.");
      updateUI(
          false,
          true,
          lockDuration ~/
              1000); // Update UI: disable biometrics, set locked, start countdown

      startCountdown(userId);
    } else {
      await _firestore.collection('customers').doc(userId).update({
        'failedAttempts': failedAttempts,
      });

      showErrorSnackbar(
          "Biometric login failed. Attempt $failedAttempts of 3.");
    }
  }

  Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<String> validatePassword(String password) async {
    final RegExp passwordRegExp = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

    if (password.isEmpty) {
      return "Password is required";
    } else if (!passwordRegExp.hasMatch(password)) {
      return "Password must be at least 8 characters long, include an uppercase letter, a lowercase letter, a number, and a special character.";
    }
    return "VALID"; // Password is valid
  }
}
