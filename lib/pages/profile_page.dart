//profile page

//update profile

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();
  final AuthService _authService = AuthService();

  String name = "Loading...";
  String email = "Loading...";
  String phone = "Loading...";
  String address = "Loading...";
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadBiometricStatus();
  }

  void _signOut() async {
    // await _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _fetchUserData() async {
    try {
      String? savedEmail = await secureStorage.read(key: 'email');
      if (savedEmail != null) {
        setState(() {
          email = savedEmail;
        });

        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .where('email', isEqualTo: savedEmail)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = querySnapshot.docs.first;
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            name = userData['name'] ?? "No Name";
            phone = userData['phone'] ?? "No Phone";
            address = userData['address'] ?? "No Address";
          });
        }
      }
    } catch (e) {
      print(" Error fetching user data: $e");
    }
  }

  Future<void> _loadBiometricStatus() async {
    String? biometricEnabled =
        await secureStorage.read(key: 'biometric_enabled');
    setState(() {
      _isBiometricEnabled = biometricEnabled == 'true';
    });
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (enabled) {
      bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (canAuthenticate) {
        bool isAuthenticated = await auth.authenticate(
          localizedReason: 'Enable biometric login',
          options: const AuthenticationOptions(
            biometricOnly: true,
            useErrorDialogs: true,
            stickyAuth: true,
          ),
        );

        if (isAuthenticated) {
          String? savedEmail = await secureStorage.read(key: 'email');

          if (savedEmail == null || savedEmail.isEmpty) {
            print("⚠️ No email found, storing it now...");

            // Fetch email from Firestore again if needed
            QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                .collection('customers')
                .limit(1)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              DocumentSnapshot userDoc = querySnapshot.docs.first;
              Map<String, dynamic> userData =
                  userDoc.data() as Map<String, dynamic>;
              savedEmail = userData['email'];
              await secureStorage.write(key: 'email', value: savedEmail);
              print("✅ Email stored for biometric login: $savedEmail");
            }
          }

          await secureStorage.write(key: 'biometric_enabled', value: 'true');
          setState(() => _isBiometricEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Biometric login enabled")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Biometric authentication not supported on this device")),
        );
      }
    } else {
      await secureStorage.write(key: 'biometric_enabled', value: 'false');
      setState(() => _isBiometricEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Biometric login disabled")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Profile Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ProfileCard(label: "Phone", value: phone),
                  const SizedBox(height: 10),
                  ProfileCard(label: "Address", value: address),
                  const SizedBox(height: 20),

                  // Biometric Toggle Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Enable Biometric Login",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _isBiometricEnabled,
                        onChanged: _toggleBiometric,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sign Out Button
                  ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      "Sign Out",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String label;
  final String value;

  const ProfileCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(
              "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}