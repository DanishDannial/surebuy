import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surebuy/pages/customer_home.dart';
import 'package:surebuy/pages/login_page.dart';
import 'package:surebuy/pages/payment_page.dart';
import 'package:surebuy/pages/signup_page.dart';
import 'package:surebuy/pages/payment_completion_page.dart';
import 'package:surebuy/providers/cart_provider.dart';
import 'package:uni_links5/uni_links.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  FirebaseAuth.instance.setLanguageCode("en");

  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (context) => CartProvider())],
    child: const MainApp(),
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    _sub?.cancel(); // Cancel the listener when app is closed
    super.dispose();
  }

  void _initDeepLinkListener() {
    _sub = linkStream.listen((String? link) {
      if (link != null && link.contains("surebuy://return")) {
        print("Redirecting to success page!");
        Navigator.pushNamed(context, "/success"); // Navigate to success screen
      }
    }, onError: (err) {
      print("Deep linking error: $err");
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: "/login",
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          "/customer_home": (context) => const CustomerHome(),
          "/payment": (context) => const PaymentPage(totalAmount: 0.0),
          "/success": (context) => const PaymentSuccessPage(success: true),
        },
    );
  }
}

//class PaymentSuccessPage extends StatelessWidget {
//  final bool success;
//
//  const PaymentSuccessPage({required this.success});
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(title: const Text("Payment Result")),
//      body: Center(
//        child: Text(success ? "Payment Successful" : "Payment Failed",
//            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//      ),
//    );
//  }
//}
