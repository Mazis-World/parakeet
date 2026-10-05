import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parakeet/booking.dart';
import 'package:parakeet/messaging.dart';
import 'package:parakeet/reviews.dart';
import 'package:parakeet/profile.dart';
import 'package:share_plus/share_plus.dart';

class PetDetailScreen extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic> listingData;

  const PetDetailScreen({
    super.key,
    required this.listingId,
    required this.listingData,
  });

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favorite = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.listingId)
        .get();

    if (mounted) {
      setState(() {
        _isFavorite = favorite.exists;
      });
    }
  }

  Future<void> _toggleFavorite(BuildContext context, String listingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add favorites')),
      );
      return;
    }

    try {
      if (_isFavorite) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(listingId)
            .delete();
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(listingId)
            .set({
          'listingId': listingId,
          'addedAt': Timestamp.now(),
        });
        if (mounted) {
          setState(() {
            _isFavorite = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _shareListing(BuildContext context, String petName, String listingId) async {
    try {
      await Share.share(
        'Check out $petName on Parakeet! 🦜\n\nFind your perfect pet companion.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingId = widget.listingId;
    final listingData = widget.listingData;
    final images = listingData['images'] as List<dynamic>? ?? [];
    final name = listingData['name'] as String? ?? 'Unnamed';
    final animalType = listingData['animalType'] as String? ?? 'Unknown';
    final breed = listingData['breed'] as String? ?? 'Not specified';
    final age = listingData['age'] as String? ?? 'Not specified';
    final gender = listingData['gender'] as String? ?? 'Not specified';
    final color = listingData['color'] as String? ?? 'Not specified';
    final weight = listingData['weight'] as String? ?? 'Not specified';
    final temperament = listingData['temperament'] as String? ?? 'Not specified';
    final spayedNeutered = listingData['spayedNeutered'] as bool? ?? false;
    final microchipNumber = listingData['microchipNumber'] as String?;
    final recentVetCheckDate = listingData['recentVetCheckDate'] as String?;
    final trainingStatus = listingData['trainingStatus'] as List<dynamic>? ?? [];
    final socialization = listingData['socialization'] as String?;
    final exerciseRequirements = listingData['exerciseRequirements'] as String?;
    final coatMaintenance = listingData['coatMaintenance'] as String?;
    final sheddingLevel = listingData['sheddingLevel'] as String?;
    final preferredDiet = listingData['preferredDiet'] as String?;
    final feedingSchedule = listingData['feedingSchedule'] as String?;
    final adoptionSource = listingData['adoptionSource'] as String?;
    final licensingInfo = listingData['licensingInfo'] as String?;
    
    // Host information
    final hostName = listingData['hostName'] as String? ?? 'Unknown Host';
    final hostEmail = listingData['hostEmail'] as String?;
    final hostId = listingData['hostId'] as String?;
    
    // Pricing information (if available)
    final pricing = listingData['pricing'] as Map<String, dynamic>?;
    final dailyRate = pricing?['dailyRate'] as double?;
    final weeklyRate = pricing?['weeklyRate'] as double?;
    final currency = pricing?['currency'] as String? ?? 'CAD';
    
    // Rating information (if available)
    final rating = listingData['rating'] as double?;
    final reviewCount = listingData['reviewCount'] as int? ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pet Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            if (images.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.pets, size: 64, color: Colors.grey),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.pets, size: 64, color: Colors.grey),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet Name and Basic Info
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$animalType • $breed',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  // Rating display (if available)
                  if (rating != null && rating > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reviewCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  
                  // Pricing display (if available)
                  if (dailyRate != null || weeklyRate != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.black),
                          const SizedBox(width: 8),
                          if (dailyRate != null)
                            Text(
                              '$currency${dailyRate.toStringAsFixed(2)}/day',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (dailyRate != null && weeklyRate != null)
                            const Text(' • ', style: TextStyle(fontSize: 16)),
                          if (weeklyRate != null)
                            Text(
                              '$currency${weeklyRate.toStringAsFixed(2)}/week',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Host Profile Card
                  GestureDetector(
                    onTap: () {
                      if (hostId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: hostId),
                          ),
                        );
                      }
                    },
                    child: _buildHostCard(
                      hostName: hostName,
                      hostEmail: hostEmail,
                      hostId: hostId,
                      listingId: listingId,
                      petName: name,
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Reviews Section
                  _buildSection(
                    'Reviews',
                    [
                      ReviewsList(petListingId: listingId, limit: 5),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          // Show all reviews
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 600),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppBar(
                                      title: const Text('All Reviews'),
                                      backgroundColor: Colors.white,
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: ReviewsList(petListingId: listingId),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Text('View All Reviews'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Basic Information Section
                  _buildSection(
                    'Basic Information',
                    [
                      _buildInfoRow('Age', age),
                      _buildInfoRow('Gender', gender),
                      _buildInfoRow('Color', color),
                      _buildInfoRow('Weight', weight),
                      _buildInfoRow('Spayed/Neutered', spayedNeutered ? 'Yes' : 'No'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Health Information Section
                  _buildSection(
                    'Health Information',
                    [
                      if (microchipNumber != null && microchipNumber!.isNotEmpty)
                        _buildInfoRow('Microchip Number', microchipNumber!),
                      if (recentVetCheckDate != null && recentVetCheckDate!.isNotEmpty)
                        _buildInfoRow('Last Vet Check', recentVetCheckDate!),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Behavioral Information Section
                  _buildSection(
                    'Behavioral Information',
                    [
                      _buildInfoRow('Temperament', temperament),
                      if (socialization != null && socialization!.isNotEmpty)
                        _buildInfoRow('Socialization', socialization!),
                      if (exerciseRequirements != null && exerciseRequirements!.isNotEmpty)
                        _buildInfoRow('Exercise Requirements', exerciseRequirements!),
                      if (trainingStatus.isNotEmpty)
                        _buildInfoRow('Training Status', trainingStatus.join(', ')),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Grooming Section
                  if (coatMaintenance != null || sheddingLevel != null)
                    _buildSection(
                      'Grooming Needs',
                      [
                        if (coatMaintenance != null && coatMaintenance!.isNotEmpty)
                          _buildInfoRow('Coat Maintenance', coatMaintenance!),
                        if (sheddingLevel != null && sheddingLevel!.isNotEmpty)
                          _buildInfoRow('Shedding Level', sheddingLevel!),
                      ],
                    ),

                  if (coatMaintenance != null || sheddingLevel != null)
                    const SizedBox(height: 24),

                  // Diet Section
                  if (preferredDiet != null || feedingSchedule != null)
                    _buildSection(
                      'Diet and Feeding',
                      [
                        if (preferredDiet != null && preferredDiet!.isNotEmpty)
                          _buildInfoRow('Preferred Diet', preferredDiet!),
                        if (feedingSchedule != null && feedingSchedule!.isNotEmpty)
                          _buildInfoRow('Feeding Schedule', feedingSchedule!),
                      ],
                    ),

                  if (preferredDiet != null || feedingSchedule != null)
                    const SizedBox(height: 24),

                  // Additional Information Section
                  if (adoptionSource != null || licensingInfo != null)
                    _buildSection(
                      'Additional Information',
                      [
                        if (adoptionSource != null && adoptionSource!.isNotEmpty)
                          _buildInfoRow('Adoption Source', adoptionSource!),
                        if (licensingInfo != null && licensingInfo!.isNotEmpty)
                          _buildInfoRow('Licensing Info', licensingInfo!),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Booking Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingScreen(
                              listingId: listingId,
                              listingData: listingData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Request to Book',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostCard({
    required String hostName,
    String? hostEmail,
    String? hostId,
    required String listingId,
    required String petName,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Host Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.black,
            child: Text(
              hostName.isNotEmpty ? hostName[0].toUpperCase() : 'H',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Host Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hosted by',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hostName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hostEmail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hostEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Message button
          IconButton(
            icon: const Icon(Icons.message, color: Colors.black),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in to message')),
                );
                return;
              }

              // Check if hostId is valid
              if (hostId == null || hostId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid listing: missing host information')),
                );
                return;
              }

              // Check if user is trying to message themselves
              if (hostId == user.uid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You cannot message yourself')),
                );
                return;
              }

              try {
                final conversationId = await createOrGetConversation(
                  userId1: user.uid,
                  userId2: hostId,
                  userName1: user.displayName ?? user.email?.split('@')[0] ?? 'Unknown',
                  userName2: hostName,
                  userEmail1: user.email,
                  userEmail2: hostEmail,
                  petListingId: listingId,
                  petName: petName,
                );

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversationId,
                        otherUserId: hostId,
                        otherUserName: hostName,
                        otherUserEmail: hostEmail,
                        petName: petName,
                        petListingId: listingId,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error starting conversation: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Message host',
          ),
        ],
      ),
    );
  }
}

