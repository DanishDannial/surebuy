import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:surebuy/pages/product_details_page.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedGroup = 'All';

  List<Map<String, dynamic>> _getFilteredItems(
      List<Map<String, dynamic>> groups, String group, String query) {
    List<Map<String, dynamic>> itemsToShow = [];

    if (group == 'All') {
      itemsToShow = groups;
    } else {
      itemsToShow = groups.where((g) => g['title'] == group).toList();
    }

    if (query.isNotEmpty) {
      itemsToShow = itemsToShow.map((group) {
        final filteredItems = (group['items'] as List)
            .map((item) => item.toString())
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return {
          'title': group['title'],
          'image': group['image'],
          'items': filteredItems,
          'price': group['price'],
          'stock': group['stock'],
          'status': group['status'],
          'id': group['id'],
        };
      }).where((group) => (group['items'] as List).isNotEmpty).toList();
    }

    return itemsToShow;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFF8FAFC),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Discover',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find the perfect items for you',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                },
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: "Search for products...",
                  hintStyle: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_outlined,
                    color: Color(0xFF4A90E2),
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Men', 'Women', 'Kids']
                    .map((group) => Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: FilterChip(
                            label: Text(
                              group,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: selectedGroup == group
                                    ? Colors.white
                                    : const Color(0xFF4A90E2),
                              ),
                            ),
                            selected: selectedGroup == group,
                            onSelected: (selected) {
                              setState(() {
                                selectedGroup = group;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF4A90E2),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: selectedGroup == group
                                  ? const Color(0xFF4A90E2)
                                  : const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: selectedGroup == group ? 4 : 0,
                            shadowColor: const Color(0xFF4A90E2).withOpacity(0.3),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Products Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("products")
                    .where('status', isEqualTo: 'Available')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A90E2),
                        ),
                      ),
                    );
                  }

                  final groups = snapshot.data!.docs.map((doc) {
                    return {
                      'title': doc['category'],
                      'image': doc['image'],
                      'items': (doc['name'] is List)
                          ? doc['name']
                          : [doc['name']],
                      'price': [doc['price'].toString()],
                      'stock': doc['stock'],
                      'status': doc['status'],
                      'id': doc.id,
                    };
                  }).toList();

                  final filteredGroups = _getFilteredItems(
                      groups, selectedGroup, _searchController.text);

                  if (filteredGroups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No products found",
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Try adjusting your search or filters",
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) {
                      final product = filteredGroups[index];
                      final itemName = (product['items'] as List).isNotEmpty
                          ? product['items'][0]
                          : '';
                      final image = product['image'];
                      final price = (product['price'] as List).isNotEmpty
                          ? product['price'][0]
                          : '';
                      final productId = product['id'];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(
                                id: productId,
                                itemName: itemName,
                                imageUrl: image,
                                price: price,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    child: Image.network(
                                      image,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade50,
                                          child: const Icon(
                                            Icons.image_outlined,
                                            size: 48,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              // Product Info
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        itemName,
                                        style: const TextStyle(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'RM $price',
                                        style: const TextStyle(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4A90E2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}