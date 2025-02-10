import 'package:flutter/material.dart';
import 'package:parakeet/create_companion.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // App Logo
            Image.asset(
              'assets/perakeet_legacy.png', // Replace with your app logo
              height: 68,
            ),
            const SizedBox(width: 16), // Space between the logo and search bar

            // Search Bar
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16), // Space on the right for the filter button
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search animals...',
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Filter Button
            GestureDetector(
              onTap: () {
                // Handle filter action
              },
              child: Image.asset(
                'assets/icon_filter.png', // Custom filter icon
                height: 28,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Categories Section with horizontal scrolling
            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryItem('assets/icon_dog.png', 'Dogs'),
                    _buildCategoryItem('assets/icon_cat.png', 'Cats'),
                    _buildCategoryItem('assets/icon_bird.png', 'Birds'),
                    _buildCategoryItem('assets/icon_mouse.png', 'Rodents'),
                    _buildCategoryItem('assets/icon_snake.png', 'Reptiles'),
                    _buildCategoryItem('assets/icon_fish.png', 'Aquatic'),
                    _buildCategoryItem('assets/icon_dog.png', 'Farm Animals'),
                    _buildCategoryItem('assets/icon_cat.png', 'Exotic Animals'),
                    _buildCategoryItem('assets/icon_bird.png', 'Wildlife'),
                    _buildCategoryItem('assets/icon_mouse.png', 'Insects'),
                    _buildCategoryItem('assets/icon_snake.png', 'Aquatic Mammals'),
                    _buildCategoryItem('assets/icon_fish.png', 'Amphibians'),
                    _buildCategoryItem('assets/icon_dog.png', 'Birds of Prey'),
                    _buildCategoryItem('assets/icon_cat.png', 'Small Mammals'),
                    _buildCategoryItem('assets/icon_bird.png', 'Primates'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button to launch AnimalFormScreen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the AnimalFormScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnimalFormScreen()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,// Change this to your desired color
      ),
    );
  }

  Widget _buildCategoryItem(String iconPath, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            height: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
