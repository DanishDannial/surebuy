import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surebuy/pages/payment_page.dart';
import '../providers/cart_provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      cartProvider.fetchCartItems(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Cart")),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return const Center(child: Text("Your cart is empty."));
          }

          double subtotal = cartProvider.items.fold(
            0.0,
            (sum, item) => sum + (item.price * item.quantity),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              item.imageUrl.isNotEmpty
                                  ? Image.network(item.imageUrl, width: 80, height: 80)
                                  : const Icon(Icons.shopping_cart, size: 80),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.itemName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                      "RM ${item.price.toStringAsFixed(2)}"
                                      "${item.size != null && item.size.isNotEmpty ? " | Size: ${item.size}" : ""}",
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user != null &&
                                                item.id != null &&
                                                item.quantity > 1) {
                                              cartProvider.updateQuantity(
                                                  user.uid, item.id!, item.quantity - 1);
                                            }
                                          },
                                        ),
                                        Text('${item.quantity}',
                                            style: const TextStyle(fontSize: 16)),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user != null && item.id != null) {
                                              cartProvider.updateQuantity(
                                                  user.uid, item.id!, item.quantity + 1);
                                            }
                                          },
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user != null && item.id != null) {
                                              cartProvider.removeFromCart(user.uid, item.id!);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("RM ${subtotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(totalAmount: subtotal),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text("Proceed to Payment"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}