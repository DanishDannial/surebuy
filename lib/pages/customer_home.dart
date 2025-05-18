import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:surebuy/pages/cart_page.dart';
//import 'package:surebuy/pages/login_page.dart';
import 'package:surebuy/pages/profile_page.dart';
import 'package:surebuy/pages/shopping_page.dart';
import 'package:surebuy/pages/wishlist_page.dart';
// import 'package:surebuy/services/auth_service.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  // final AuthService _authService = AuthService();
  int _page = 0;

  final List<Widget> _pages = [
    const ShoppingPage(),
    const CartPage(),
    const WishListPage(),
    const ProfilePage()
  ];

//  void _signOut() async {
//    // await _authService.logout();
//    Navigator.pushAndRemoveUntil(
//      context,
//      MaterialPageRoute(builder: (context) => const LoginScreen()),
//      (Route<dynamic> route) => false,
//    );
// }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Blank top section
            const SizedBox(height: 16.0),
            // Main content
            Expanded(
              child: _pages[_page],
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: Colors.blue,
        color: Colors.blue,
        animationDuration: const Duration(milliseconds: 300),
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.shopping_cart, size: 30, color: Colors.white),
          Icon(Icons.favorite, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
      ),
    );
  }
}

// class CategoriesScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//         itemCount: categories.length,
//         itemBuilder: (context, index) {
//           return GestureDetector(
//             child: Card(
//               margin: EdgeInsets.all(10),
//               shape: RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(15), // Set the card's corner radius
//               ),
//               elevation: 5, // Add shadow to the card
//               child: SizedBox(
//                 height: 150, // Adjust the height of the card
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(
//                       15), // Match the card's corner radius
//                   child: Stack(
//                     fit: StackFit
//                         .expand, // Ensures the background image covers the entire card
//                     children: [
//                       // Background Image
//                       Container(
//                         decoration: const BoxDecoration(
//                           image: DecorationImage(
//                             image: AssetImage(
//                                 'assets/background.jpg'), // Replace with your image path
//                             fit: BoxFit
//                                 .cover, // Ensures the image covers the entire space
//                           ),
//                         ),
//                       ),
//                       // Semi-transparent overlay (optional for readability)
//                       Container(
//                         color: Colors.black.withOpacity(
//                             0.5), // Adjust opacity for better text visibility
//                       ),
//                       // Title
//                       Center(
//                         child: Text(
//                           categories[index]['title'],
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors
//                                 .white, // Ensure text contrasts the background
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       ItemsScreen(category: categories[index]),
//                 ),
//               );
//             },
//           );
//         });
//   }
// }
//
// class ItemsScreen extends StatelessWidget {
//   final Map<String, dynamic> category;
//
//   ItemsScreen({required this.category});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${category['title']} Items'),
//         backgroundColor: Colors.teal,
//       ),
//       body: GridView.builder(
//         padding: EdgeInsets.all(10),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2, // Number of items per row
//           mainAxisSpacing: 10,
//           crossAxisSpacing: 10,
//           childAspectRatio: 2, // Adjust height/width ratio of grid items
//         ),
//         itemCount: category['items'].length,
//         itemBuilder: (context, index) {
//           return Container(
//             decoration: BoxDecoration(
//               color: Colors.teal[100],
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(
//               child: Text(
//                 category['items'][index],
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
