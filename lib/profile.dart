import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parakeet/companions.dart';
import 'package:parakeet/bookings.dart';
import 'package:parakeet/reviews.dart';
import 'package:parakeet/firestore_errors.dart';
import 'package:parakeet/settings.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final profileUserId = userId ?? currentUser?.uid ?? '';

    if (profileUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view profile'),
        ),
      );
    }

    final isOwnProfile = profileUserId == currentUser?.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: isOwnProfile
              ? [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ]
              : null,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'About'),
              Tab(text: 'Listings'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(profileUserId)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final authUser = userId == null ? currentUser : null;

            return TabBarView(
              children: [
                _AboutTab(
                  userId: profileUserId,
                  userData: userData,
                  authUser: authUser,
                  isOwnProfile: isOwnProfile,
                ),
                _ListingsTab(userId: profileUserId, isOwnProfile: isOwnProfile),
                _ReviewsTab(userId: profileUserId),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final User? authUser;
  final bool isOwnProfile;

  const _AboutTab({
    required this.userId,
    required this.userData,
    this.authUser,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = userData['displayName'] as String? ??
        authUser?.displayName ??
        authUser?.email?.split('@')[0] ??
        'Unknown';
    final email = userData['email'] as String? ?? authUser?.email ?? '';
    final bio = userData['bio'] as String? ?? '';
    final phoneNumber = userData['phoneNumber'] as String? ?? '';
    final location = userData['location'] as Map<String, dynamic>?;
    final city = location?['city'] as String?;
    final province = location?['province'] as String?;
    final verificationStatus = userData['verificationStatus'] as String? ?? 'unverified';
    final userType = userData['userType'] as String? ?? 'renter';

    final hostStats = userData['hostStats'] as Map<String, dynamic>? ?? {};
    final renterStats = userData['renterStats'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.black,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (verificationStatus == 'verified')
                      Icon(Icons.verified, color: Colors.blue, size: 24),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (city != null || province != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [city, province].where((e) => e != null).join(', '),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Listings',
                  value: '${hostStats['totalListings'] ?? 0}',
                  icon: Icons.pets,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Bookings',
                  value: '${renterStats['totalBookings'] ?? 0}',
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Rating',
                  value: hostStats['averageRating'] != null
                      ? (hostStats['averageRating'] as double).toStringAsFixed(1)
                      : 'N/A',
                  icon: Icons.star,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bio Section
          if (bio.isNotEmpty || isOwnProfile) ...[
            const Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: bio.isNotEmpty
                  ? Text(
                      bio,
                      style: const TextStyle(fontSize: 14),
                    )
                  : Text(
                      isOwnProfile
                          ? 'Add a bio to tell others about yourself'
                          : 'No bio available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],

          // Contact Information
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.email, label: 'Email', value: email),
          if (phoneNumber.isNotEmpty)
            _InfoRow(icon: Icons.phone, label: 'Phone', value: phoneNumber),
          _InfoRow(
            icon: Icons.person,
            label: 'User Type',
            value: userType == 'host'
                ? 'Host'
                : userType == 'renter'
                    ? 'Renter'
                    : 'Both',
          ),
          _InfoRow(
            icon: Icons.verified_user,
            label: 'Verification',
            value: verificationStatus == 'verified'
                ? 'Verified'
                : verificationStatus == 'pending'
                    ? 'Pending'
                    : 'Not Verified',
          ),

          const SizedBox(height: 24),

          // Action Buttons (if own profile)
          if (isOwnProfile) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Edit profile
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Edit Profile'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingsTab extends StatelessWidget {
  final String userId;
  final bool isOwnProfile;

  const _ListingsTab({
    required this.userId,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('listings')
          .where('hostId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return FirestoreErrorView(error: snapshot.error);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No listings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: Icon(Icons.pets, color: Colors.white),
                ),
                title: Text(
                  data['name'] as String? ?? 'Unnamed',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(data['animalType'] as String? ?? 'Unknown'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetDetailScreen(
                        listingId: doc.id,
                        listingData: data,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final String userId;

  const _ReviewsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('hostId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return FirestoreErrorView(error: snapshot.error);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.reviews, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _ReviewCard(reviewData: data);
          },
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> reviewData;

  const _ReviewCard({required this.reviewData});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final rating = reviewData['rating'] as int? ?? 0;
    final comment = reviewData['comment'] as String? ?? '';
    final renterName = reviewData['renterName'] as String? ?? 'Anonymous';
    final createdAt = reviewData['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.black,
                  child: Text(
                    renterName.isNotEmpty ? renterName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        renterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: index < rating ? Colors.amber : Colors.grey,
                    );
                  }),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

