import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:provider/provider.dart';
import 'package:surebuy/pages/payment_completion_page.dart';
import '../services/toyyibpay_service.dart';

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
        apiKey: "n3yxm20v-d82i-4mzo-n11k-5rxlp3ei45hw",
        categoryCode: "mng6ctzd",
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Total Amount:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("RM ${widget.totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(height: 30),
            isProcessing
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text("Pay Now"),
                  ),
          ],
        ),
      ),
    );
  }
}