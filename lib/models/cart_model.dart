class CartItem {
  final String id;
  final String itemId;
  final String itemName;
  final double price;
  final String imageUrl;
  final String size;
  int quantity;

  CartItem({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.imageUrl,
    required this.size,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'price': price,
      'imageUrl': imageUrl,
      'size': size,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    return CartItem(
      id: id,
      itemId: map['itemId'],
      itemName: map['itemName'],
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'],
      size: map['size'],
      quantity: map['quantity'],
    );
  }
}