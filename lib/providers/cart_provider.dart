import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/cart_model.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  List<CartItem> get items => _items;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchCartItems(String userId) async {
    final snapshot = await _firestore
        .collection('cart')
        .doc(userId)
        .collection('items')
        .get();

    _items = snapshot.docs
        .map((doc) => CartItem.fromMap(doc.id, doc.data()))
        .toList();
    notifyListeners();
  }

  Future<void> addToCart(CartItem item, String userId) async {
    final ref = _firestore.collection('cart').doc(userId).collection('items');

    // Check if already in cart (match by itemId and size)
    final existing = await ref
        .where('itemId', isEqualTo: item.itemId)
        .where('size', isEqualTo: item.size)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      await ref.doc(doc.id).update({'quantity': FieldValue.increment(item.quantity)});
    } else {
      await ref.add(item.toMap());
    }

    await fetchCartItems(userId);
  }

  Future<void> removeFromCart(String userId, String cartItemId) async {
    final ref = _firestore.collection('cart').doc(userId).collection('items');
    await ref.doc(cartItemId).delete();
    await fetchCartItems(userId);
  }

  Future<void> updateQuantity(String userId, String cartItemId, int newQuantity) async {
    final ref = _firestore.collection('cart').doc(userId).collection('items');
    if (newQuantity <= 0) {
      await ref.doc(cartItemId).delete();
    } else {
      await ref.doc(cartItemId).update({'quantity': newQuantity});
    }
    await fetchCartItems(userId);
  }

  Future<void> clearCart(String userId) async {
    final cartItems = await _firestore
        .collection('cart')
        .doc(userId)
        .collection('items')
        .get();

    for (var doc in cartItems.docs) {
      await doc.reference.delete();
    }

    _items = [];
    notifyListeners();
  }

  Future<void> convertCartToOrder(String userId) async {
    final cartRef = _firestore.collection('cart').doc(userId).collection('items');
    final cartItems = await cartRef.get();

    if (cartItems.docs.isEmpty) return;

    final customerRef = _firestore.collection('customers').doc(userId);

    for (var doc in cartItems.docs) {
      final data = doc.data();
      final productRef = _firestore.collection('products').doc(data['itemId']);
      final quantity = data['quantity'] ?? 1;
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final size = data['size'] ?? '';
      final totalPrice = price * quantity;

      await _firestore.collection('orders').add({
        'customerRef': customerRef,
        'date': FieldValue.serverTimestamp(),
        'productRef': productRef,
        'quantity': quantity,
        'size': size,
        'status': 'Pending',
        'totalPrice': totalPrice,
      });

      await doc.reference.delete();
    }

    _items = [];
    notifyListeners();
  }
}