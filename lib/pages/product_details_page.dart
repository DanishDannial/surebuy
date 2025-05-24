import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:surebuy/models/cart_model.dart';
import 'package:surebuy/pages/payment_page.dart';
import '../providers/cart_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final String itemName;
  final String imageUrl;
  final String price;
  final String id;

  const ProductDetailPage({
    super.key,
    required this.itemName,
    required this.imageUrl,
    required this.price,
    required this.id,
  });

  @override
  ProductDetailPageState createState() => ProductDetailPageState();
}

class ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  bool wishlistClick = false;
  String? selectedSize;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String? productDescription;
  bool isLoadingDescription = true;

  @override
  void initState() {
    super.initState();
    _fetchProductDescription();
    _checkIfWishListed();
  }

  Future<void> _fetchProductDescription() async {
    try {
      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.id)
          .get();

      if (productDoc.exists) {
        setState(() {
          productDescription =
              productDoc['description'] ?? "No description available.";
          isLoadingDescription = false;
        });
      } else {
        setState(() {
          productDescription = "Product description not found.";
          isLoadingDescription = false;
        });
      }
    } catch (e) {
      setState(() {
        productDescription = "Failed to load description.";
        isLoadingDescription = false;
      });
      print("Error fetching product description: $e");
    }
  }

  void increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  Future<void> toggleWishList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to use wishlist.")),
      );
      return;
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection('wishlist')
        .doc(user.uid)
        .collection('items')
        .doc(widget.id);

    if (wishlistClick) {
      await wishlistRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.itemName} removed from wishlist")),
      );
    } else {
      await wishlistRef.set({
        'itemName': widget.itemName,
        'imageUrl': widget.imageUrl,
        'price': widget.price,
        // add more fields if needed
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.itemName} added to wishlist")),
      );
    }
    setState(() {
      wishlistClick = !wishlistClick;
    });
  }

  Future<void> _checkIfWishListed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final wishlistDoc = await FirebaseFirestore.instance
        .collection('wishlist')
        .doc(user.uid)
        .collection('items')
        .doc(widget.id)
        .get();
    setState(() {
      wishlistClick = wishlistDoc.exists;
    });
  }

  Future<String?> getCustomerId() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      return await _fetchUserIdFromStorage();
    }
  }

  Future<String?> _fetchUserIdFromStorage() async {
    String? savedEmail = await secureStorage.read(key: 'email');
    if (savedEmail == null) return null;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('email', isEqualTo: savedEmail)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
          icon: wishlistClick
              ? const Icon(Icons.favorite, color: Colors.red)
              : const Icon(Icons.favorite_border),
          onPressed: toggleWishList,
        ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Image.network(
                      widget.imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.fitHeight,
                    ),
                    const SizedBox(height: 16),

                    // Product Name and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.itemName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'RM ${widget.price}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Available Sizes
                    const Text(
                      "Size:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizeOption(
                          size: "S",
                          isSelected: selectedSize == "S",
                          onTap: () {
                            setState(() {
                              selectedSize = "S";
                            });
                          },
                        ),
                        SizeOption(
                          size: "M",
                          isSelected: selectedSize == "M",
                          onTap: () {
                            setState(() {
                              selectedSize = "M";
                            });
                          },
                        ),
                        SizeOption(
                          size: "L",
                          isSelected: selectedSize == "L",
                          onTap: () {
                            setState(() {
                              selectedSize = "L";
                            });
                          },
                        ),
                        SizeOption(
                          size: "XL",
                          isSelected: selectedSize == "XL",
                          onTap: () {
                            setState(() {
                              selectedSize = "XL";
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Product Description
                    const Text(
                      "Product Description",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    isLoadingDescription
                        ? const CircularProgressIndicator()
                        : Text(
                            productDescription ?? "No description available.",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: decreaseQuantity,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      "$quantity",
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      onPressed: increaseQuantity,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedSize == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select a size."),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            final cartProvider =
                                Provider.of<CartProvider>(context, listen: false);
                            String? customerId = await getCustomerId();

                            if (customerId != null) {
                              await cartProvider.addToCart(
                                CartItem(
                                  id: '', // Firestore will generate this
                                  itemId: widget.id,
                                  itemName: widget.itemName,
                                  price: double.parse(widget.price),
                                  imageUrl: widget.imageUrl,
                                  size: selectedSize ?? '',
                                  quantity: quantity,
                                ),
                                customerId,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${widget.itemName} added to cart"),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please log in to add items to the cart"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_cart),
                              SizedBox(height: 4),
                              Text(
                                "Add to Cart",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedSize == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select a size."),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            try {
                              User? user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Please log in to proceed to checkout."),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              final cartProvider = Provider.of<CartProvider>(
                                  context,
                                  listen: false);
                              await cartProvider.addToCart(
                                CartItem(
                                  id: '', // Firestore will generate this
                                  itemId: widget.id,
                                  itemName: widget.itemName,
                                  price: double.parse(widget.price),
                                  imageUrl: widget.imageUrl,
                                  size: selectedSize ?? '',
                                  quantity: quantity,
                                ),
                                user.uid,
                              );

                              double totalAmount =
                                  double.parse(widget.price) * quantity;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PaymentPage(totalAmount: totalAmount),
                                ),
                              );
                            } catch (e) {
                              print("Error during checkout: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("An error occurred during checkout."),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text("Checkout"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SizeOption extends StatelessWidget {
  final String size;
  final bool isSelected;
  final VoidCallback onTap;

  const SizeOption({
    super.key,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.white,
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
        child: Text(
          size,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
