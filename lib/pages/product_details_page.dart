//version 1 product details
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
        SnackBar(
          content: const Text(
            "Please log in to use wishlist.",
            style: TextStyle(fontFamily: 'SF Pro Display'),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
        SnackBar(
          content: Text(
            "${widget.itemName} removed from wishlist",
            style: const TextStyle(fontFamily: 'SF Pro Display'),
          ),
          backgroundColor: const Color(0xFF4A90E2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      await wishlistRef.set({
        'itemName': widget.itemName,
        'imageUrl': widget.imageUrl,
        'price': widget.price,
        // add more fields if needed
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${widget.itemName} added to wishlist",
            style: const TextStyle(fontFamily: 'SF Pro Display'),
          ),
          backgroundColor: const Color(0xFF4A90E2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Product Details",
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: wishlistClick
                  ? const Icon(Icons.favorite, color: Colors.red)
                  : const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: toggleWishList,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF7BB3F0),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    // Product Image Container
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          widget.imageUrl,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                                size: 60,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Content Container
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name and Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.itemName,
                                    style: const TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4A90E2), Color(0xFF7BB3F0)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'RM ${widget.price}',
                                    style: const TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Available Sizes
                            const Text(
                              "Size",
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 10),

                            // Product Description
                            const Text(
                              "Product Description",
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: isLoadingDescription
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF4A90E2),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      productDescription ?? "No description available.",
                                      style: const TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 15,
                                        color: Color(0xFF7F8C8D),
                                        height: 1.5,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, 
                  children: [
                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: decreaseQuantity,
                            icon: const Icon(
                              Icons.remove,
                              color: Color(0xFF4A90E2),
                            ),
                            padding: const EdgeInsets.all(8), // Reduced padding
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            //constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            child: Text(
                              "$quantity",
                              style: const TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: increaseQuantity,
                            icon: const Icon(
                              Icons.add,
                              color: Color(0xFF4A90E2),
                            ),
                            padding: const EdgeInsets.all(8), 
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Action Buttons
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF4A90E2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (selectedSize == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Please select a size.",
                                          style: TextStyle(fontFamily: 'SF Pro Display'),
                                        ),
                                        backgroundColor: Colors.orange.shade400,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
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
                                        content: Text(
                                          "${widget.itemName} added to cart",
                                          style: const TextStyle(fontFamily: 'SF Pro Display'),
                                        ),
                                        backgroundColor: Colors.green.shade400,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Please log in to add items to the cart",
                                          style: TextStyle(fontFamily: 'SF Pro Display'),
                                        ),
                                        backgroundColor: Colors.red.shade400,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF4A90E2),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      "Add to Cart",
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4A90E2), Color(0xFF7BB3F0)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (selectedSize == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Please select a size.",
                                          style: TextStyle(fontFamily: 'SF Pro Display'),
                                        ),
                                        backgroundColor: Colors.orange.shade400,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    User? user = FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            "Please log in to proceed to checkout.",
                                            style: TextStyle(fontFamily: 'SF Pro Display'),
                                          ),
                                          backgroundColor: Colors.red.shade400,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
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
                                      SnackBar(
                                        content: const Text(
                                          "An error occurred during checkout.",
                                          style: TextStyle(fontFamily: 'SF Pro Display'),
                                        ),
                                        backgroundColor: Colors.red.shade400,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Checkout",
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A90E2) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              size,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}