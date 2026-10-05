import 'package:flutter/material.dart';
import 'package:parakeet/create_companion.dart';
import 'package:parakeet/companions.dart';
import 'package:parakeet/bookings.dart';
import 'package:parakeet/messaging.dart';
import 'package:parakeet/profile.dart';
import 'package:parakeet/payments.dart';
import 'package:parakeet/host_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';
  
  // Advanced filter options
  String? _selectedAnimalType;
  String? _selectedGender;
  String? _minAge;
  String? _maxAge;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Map category labels to animal types for filtering
  String? _getAnimalTypeFromCategory(String category) {
    final categoryMap = {
      'Dogs': 'Dog',
      'Cats': 'Cat',
      'Birds': 'Bird',
      'Rodents': 'Rodent',
      'Reptiles': 'Reptile',
      'Aquatic': 'Aquatic',
      'Farm Animals': 'Farm Animal',
      'Exotic Animals': 'Exotic',
      'Wildlife': 'Wildlife',
      'Insects': 'Insect',
      'Aquatic Mammals': 'Aquatic Mammal',
      'Amphibians': 'Amphibian',
      'Birds of Prey': 'Bird of Prey',
      'Small Mammals': 'Small Mammal',
      'Primates': 'Primate',
    };
    return categoryMap[category];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConversationsScreen()),
              );
            },
            tooltip: 'Messages',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookingsScreen()),
              );
            },
            tooltip: 'My Bookings',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionsScreen()),
              );
            },
            tooltip: 'Transactions',
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Profile',
          ),
        ],
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
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
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
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            // Filter Button
            GestureDetector(
              onTap: () {
                _showFilterDialog(context);
              },
              child: Stack(
                children: [
                  Image.asset(
                    'assets/icon_filter.png', // Custom filter icon
                    height: 28,
                  ),
                  if (_hasActiveFilters())
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Modern Categories Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
          // Pet Listings Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                // Filter documents based on search query and category
                List<QueryDocumentSnapshot> filteredDocs = [];
                if (snapshot.hasData) {
                  filteredDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _matchesFilters(data);
                  }).toList();
                }
                
                if (!snapshot.hasData || filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _hasActiveFilters() 
                              ? 'No pets match your filters'
                              : 'No pets listed yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasActiveFilters()
                              ? 'Try adjusting your search or filters'
                              : 'Be the first to list a pet!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (_hasActiveFilters()) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _clearAllFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black,
                            ),
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildPetCard(context, doc.id, data);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Floating Action Button - Show different options based on user type
      floatingActionButton: FirebaseAuth.instance.currentUser != null
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('hostId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                final isHost = snapshot.hasData && 
                               snapshot.data != null && 
                               snapshot.data!.docs.isNotEmpty;
                
                return FloatingActionButton(
                  onPressed: () {
                    if (isHost) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HostDashboardScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AnimalFormScreen()),
                      );
                    }
                  },
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  tooltip: isHost ? 'Host Dashboard' : 'Create Listing',
                  child: Icon(isHost ? Icons.dashboard : Icons.add),
                );
              },
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnimalFormScreen()),
                );
              },
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              tooltip: 'Create Listing',
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildCategoryItem(String iconPath, String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedCategory == label) {
            _selectedCategory = null; // Deselect if already selected
          } else {
            _selectedCategory = label;
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                iconPath,
                height: 28,
                color: isSelected ? Colors.white : null,
                colorBlendMode: isSelected ? BlendMode.srcIn : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check if listing matches all active filters
  bool _matchesFilters(Map<String, dynamic> data) {
    // Search filter
    if (_searchQuery.isNotEmpty) {
      final name = (data['name'] as String? ?? '').toLowerCase();
      final breed = (data['breed'] as String? ?? '').toLowerCase();
      final animalType = (data['animalType'] as String? ?? '').toLowerCase();
      
      if (!name.contains(_searchQuery) && 
          !breed.contains(_searchQuery) && 
          !animalType.contains(_searchQuery)) {
        return false;
      }
    }
    
    // Category filter
    if (_selectedCategory != null) {
      final expectedType = _getAnimalTypeFromCategory(_selectedCategory!);
      final animalType = data['animalType'] as String? ?? '';
      if (expectedType != null && animalType.toLowerCase() != expectedType.toLowerCase()) {
        return false;
      }
    }
    
    // Advanced filters
    if (_selectedAnimalType != null) {
      final animalType = (data['animalType'] as String? ?? '').toLowerCase();
      if (animalType != _selectedAnimalType!.toLowerCase()) {
        return false;
      }
    }
    
    if (_selectedGender != null) {
      final gender = (data['gender'] as String? ?? '').toLowerCase();
      if (gender != _selectedGender!.toLowerCase()) {
        return false;
      }
    }
    
    // Age filter (if age is stored as a string like "2 years" or "5 months")
    if (_minAge != null || _maxAge != null) {
      final ageStr = (data['age'] as String? ?? '').toLowerCase();
      // Simple age parsing - can be improved
      // This is a basic implementation
    }
    
    return true;
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _selectedCategory != null ||
        _selectedAnimalType != null ||
        _selectedGender != null ||
        _minAge != null ||
        _maxAge != null;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _selectedAnimalType = null;
      _selectedGender = null;
      _minAge = null;
      _maxAge = null;
    });
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Pets'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animal Type Filter
                    const Text(
                      'Animal Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedAnimalType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'All Types',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Types')),
                        const DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                        const DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                        const DropdownMenuItem(value: 'Bird', child: Text('Bird')),
                        const DropdownMenuItem(value: 'Rodent', child: Text('Rodent')),
                        const DropdownMenuItem(value: 'Reptile', child: Text('Reptile')),
                        const DropdownMenuItem(value: 'Aquatic', child: Text('Aquatic')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedAnimalType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Gender Filter
                    const Text(
                      'Gender',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'All Genders',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Genders')),
                        const DropdownMenuItem(value: 'Male', child: Text('Male')),
                        const DropdownMenuItem(value: 'Female', child: Text('Female')),
                        const DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Clear Filters Button
                    if (_hasActiveFilters())
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setDialogState(() {
                              _clearAllFilters();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear All Filters'),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPetCard(BuildContext context, String listingId, Map<String, dynamic> data) {
    final images = data['images'] as List<dynamic>? ?? [];
    final firstImage = images.isNotEmpty ? images[0] as String : null;
    final name = data['name'] as String? ?? 'Unnamed';
    final animalType = data['animalType'] as String? ?? 'Unknown';
    final location = data['location'] as Map<String, dynamic>?;
    final city = location?['city'] as String? ?? '';
    final province = location?['province'] as String? ?? '';
    final locationText = city.isNotEmpty && province.isNotEmpty 
        ? '$city, $province'
        : (city.isNotEmpty ? city : 'Location not specified');
    final rating = data['rating'] as double?;
    final reviewCount = data['reviewCount'] as int? ?? 0;
    final pricing = data['pricing'] as Map<String, dynamic>?;
    final dailyRate = pricing?['dailyRate'] as double?;
    final weeklyRate = pricing?['weeklyRate'] as double?;
    final currency = pricing?['currency'] as String? ?? 'CAD';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailScreen(listingId: listingId, listingData: data),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Image with rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey.shade100,
                  child: firstImage != null
                      ? Image.network(
                          firstImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.pets,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.pets,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
                // Favorite button overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Modern Info Layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating != null && rating > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  locationText,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  animalType,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dailyRate != null || weeklyRate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${currency}\$${(dailyRate ?? weeklyRate ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        weeklyRate != null && dailyRate == null
                            ? 'per week'
                            : 'per day',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
