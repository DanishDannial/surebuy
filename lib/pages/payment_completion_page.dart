import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebView({super.key, required this.paymentUrl});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (url) {
            setState(() {
              isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.contains("surebuy://return")) {
              final uri = Uri.parse(request.url);
              final statusId = uri.queryParameters['status_id'];
              final user = FirebaseAuth.instance.currentUser;

              if (statusId == '1' && user != null) {
                // Payment successful, convert cart to order
                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                await cartProvider.convertCartToOrder(user.uid);

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentSuccessPage(success: true),
                    ),
                  );
                }
              } else {
                // Payment failed or cancelled
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentSuccessPage(success: false),
                    ),
                  );
                }
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class PaymentSuccessPage extends StatelessWidget {
  final bool success;

  const PaymentSuccessPage({super.key, required this.success});

  @override
  Widget build(BuildContext context) {
    // Redirect to the main page after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushNamedAndRemoveUntil(context, "/customer_home", (route) => false);
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Payment Result")),
      body: Center(
        child: Text(
          success ? "Payment Successful" : "Payment Failed",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}