import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:provider/provider.dart';
import 'package:surebuy/pages/payment_completion_page.dart';
import '../services/toyyibpay_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;

  const PaymentPage({super.key, required this.totalAmount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isProcessing = false;
  final ToyyibPayService _toyyibPayService = ToyyibPayService();

  void _processPayment() async {
    setState(() {
      isProcessing = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage(context, "User not logged in. Please log in and try again.");
        setState(() => isProcessing = false);
        return;
      }

      String userId = user.uid;

      // Fetch customer data from Firestore
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userId)
          .get();

      if (!customerDoc.exists) {
        _showMessage(context, "Customer not found.");
        setState(() => isProcessing = false);
        return;
      }

      Map<String, dynamic> data = customerDoc.data() as Map<String, dynamic>;
      String name = data['name'] ?? "Unknown Name";
      String email = data['email'] ?? "unknown@example.com";
      String phone = data['phone'] ?? "0000000000";

      String? bearerToken = await user.getIdToken(true);
      if (bearerToken == null) {
        _showMessage(context, "Session expired. Please re-login.");
        setState(() => isProcessing = false);
        return;
      }

      String amountString = (widget.totalAmount * 100).toInt().toString();

      // Create payment bill via ToyyibPay
      String? paymentUrl = await _toyyibPayService.createBill(
        apiKey: dotenv.env['TOYYIBPAY_API_KEY'] ?? '',
        categoryCode: dotenv.env['TOYYIBPAY_CATEGORY_CODE'] ?? '',
        billName: "Test Payment",
        billDescription: "Purchase of Goods",
        billTo: name,
        amount: amountString,
        billEmail: email,
        billPhone: phone,
        billReturnUrl: "surebuy://return",
      );

      setState(() => isProcessing = false);

      if (paymentUrl == null) {
        _showMessage(context, "Failed to generate payment URL.");
        return;
      }

      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebView(paymentUrl: "https://dev.toyyibpay.com/$paymentUrl"),
            ),
          );
        }
      });
    } catch (e) {
      setState(() => isProcessing = false);
      print("Payment Processing Error: $e");
      _showMessage(context, "An error occurred during payment. Please try again.");
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _enableSecureScreen();
  }

  @override
  void dispose() {
    _disableSecureScreen();
    super.dispose();
  }

  Future<void> _enableSecureScreen() async {
    await FlutterWindowManagerPlus.addFlags(
        FlutterWindowManagerPlus.FLAG_SECURE);
  }

  Future<void> _disableSecureScreen() async {
    await FlutterWindowManagerPlus.clearFlags(
        FlutterWindowManagerPlus.FLAG_SECURE);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Payment",
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FBFF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Payment icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF007AFF),
                        Color(0xFF0051D5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 32),
                // Payment details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Total Amount",
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                        ).createShader(bounds),
                        child: Text(
                          "RM ${widget.totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontFamily: '.SF Pro Display',
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Payment button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF007AFF),
                        Color(0xFF0051D5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isProcessing ? null : _processPayment,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Pay Securely",
                                    style: TextStyle(
                                      fontFamily: '.SF Pro Text',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Security notice
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: Colors.grey[500],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Your payment is secured with 256-bit SSL encryption",
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}