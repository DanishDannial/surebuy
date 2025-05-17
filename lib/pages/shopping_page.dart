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
  String selectedGroup = 'All'; // Default selected group

  // Get filtered items based on the group and search query
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Group Chips (All, Men, Women, Kids)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Men', 'Women', 'Kids']
                    .map((group) => ChoiceChip(
                          label: Text(group),
                          selected: selectedGroup == group,
                          onSelected: (selected) {
                            setState(() {
                              selectedGroup = group;
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {}); // Just rebuild to apply filter
              },
              decoration: InputDecoration(
                hintText: "Search items...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Real-time product list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("products")
                  .where('status', isEqualTo: 'Available')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Convert Firestore docs to groups
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

                // Apply filtering
                final filteredGroups = _getFilteredItems(
                    groups, selectedGroup, _searchController.text);

                if (filteredGroups.isEmpty) {
                  return const Center(child: Text("No products found."));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
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
                      child: Card(
                        elevation: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Image.network(
                                image,
                                fit: BoxFit.fitHeight,
                                height: 120,
                                width: double.infinity,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Title
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Price
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'RM $price',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
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
    );
  }
}