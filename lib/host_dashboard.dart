import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parakeet/companions.dart';
import 'package:parakeet/create_companion.dart';
import 'package:parakeet/bookings.dart';
import 'package:parakeet/messaging.dart';
import 'package:parakeet/availability_calendar.dart';
import 'package:parakeet/firestore_errors.dart';
import 'package:parakeet/firestore_lists.dart';
import 'package:parakeet/notifications_service.dart';
import 'package:intl/intl.dart';

class HostDashboardScreen extends StatelessWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Host Dashboard'),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view host dashboard'),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Host Dashboard',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.pets), text: 'Listings'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Bookings'),
              Tab(icon: Icon(Icons.attach_money), text: 'Earnings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(userId: user.uid),
            _ListingsTab(userId: user.uid),
            _BookingsTab(userId: user.uid),
            _EarningsTab(userId: user.uid),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String userId;

  const _OverviewTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('listings')
                .where('hostId', isEqualTo: userId)
                .snapshots(),
            builder: (context, listingsSnapshot) {
              final totalListings = listingsSnapshot.data?.docs.length ?? 0;
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('hostId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, bookingsSnapshot) {
                  final totalBookings = bookingsSnapshot.data?.docs.length ?? 0;
                  final pendingBookings = bookingsSnapshot.data?.docs
                      .where((doc) => (doc.data() as Map)['status'] == 'pending')
                      .length;
                  final completedBookings = bookingsSnapshot.data?.docs
                      .where((doc) => (doc.data() as Map)['status'] == 'completed')
                      .length;
                  
                  // Calculate total earnings
                  double totalEarnings = 0;
                  if (bookingsSnapshot.hasData) {
                    for (var doc in bookingsSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['paymentStatus'] == 'paid' && data['totalPrice'] != null) {
                        totalEarnings += (data['totalPrice'] as num).toDouble();
                      }
                    }
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Active Listings',
                              value: '$totalListings',
                              icon: Icons.pets,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Total Bookings',
                              value: '$totalBookings',
                              icon: Icons.calendar_today,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Pending Requests',
                              value: '$pendingBookings',
                              icon: Icons.pending,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Total Earnings',
                              value: 'CAD\$${totalEarnings.toStringAsFixed(2)}',
                              icon: Icons.attach_money,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent Bookings
          const Text(
            'Recent Bookings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('hostId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No bookings yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              final recent = sortDocsByTime(snapshot.data!.docs, 'createdAt').take(5);

              return Column(
                children: recent.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _BookingRequestCard(
                    bookingId: doc.id,
                    bookingData: data,
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add,
                  title: 'New Listing',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalFormScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.calendar_today,
                  title: 'View Calendar',
                  onTap: () async {
                    // Get user's first listing for calendar
                    final listings = await FirebaseFirestore.instance
                        .collection('listings')
                        .where('hostId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                        .limit(1)
                        .get();

                    if (listings.docs.isNotEmpty) {
                      final listing = listings.docs.first;
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AvailabilityCalendarScreen(
                              listingId: listing.id,
                              listingData: listing.data(),
                            ),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Create a listing first to manage availability'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingsTab extends StatelessWidget {
  final String userId;

  const _ListingsTab({required this.userId});

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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalFormScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                  ),
                  child: const Text('Create Your First Listing'),
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
            return _ListingManagementCard(
              listingId: doc.id,
              listingData: data,
            );
          },
        );
      },
    );
  }
}

class _ListingManagementCard extends StatelessWidget {
  final String listingId;
  final Map<String, dynamic> listingData;

  const _ListingManagementCard({
    required this.listingId,
    required this.listingData,
  });

  @override
  Widget build(BuildContext context) {
    final name = listingData['name'] as String? ?? 'Unnamed';
    final animalType = listingData['animalType'] as String? ?? 'Unknown';
    final status = listingData['status'] as String? ?? 'available';
    final images = listingData['images'] as List<dynamic>? ?? [];
    final firstImage = images.isNotEmpty ? images[0] as String : null;
    final rating = listingData['rating'] as double?;
    final reviewCount = listingData['reviewCount'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailScreen(
                listingId: listingId,
                listingData: listingData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: firstImage != null
                    ? Image.network(
                        firstImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.pets, size: 40),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.pets, size: 40),
                      ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      animalType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (rating != null && rating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${rating.toStringAsFixed(1)} ($reviewCount)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'available'
                            ? Colors.green[100]
                            : status == 'booked'
                                ? Colors.orange[100]
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status == 'available'
                              ? Colors.green[900]
                              : status == 'booked'
                                  ? Colors.orange[900]
                                  : Colors.grey[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    // TODO: Navigate to edit listing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit listing coming soon')),
                    );
                  } else if (value == 'delete') {
                    _deleteListing(context, listingId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'calendar',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20),
                        SizedBox(width: 8),
                        Text('Manage Availability'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteListing(BuildContext context, String listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
          'Are you sure you want to delete this listing? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('listings')
            .doc(listingId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting listing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _BookingsTab extends StatelessWidget {
  final String userId;

  const _BookingsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'All'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _HostBookingsList(userId: userId, status: 'pending'),
                _HostBookingsList(userId: userId, status: 'confirmed'),
                _HostBookingsList(userId: userId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HostBookingsList extends StatelessWidget {
  final String userId;
  final String? status;

  const _HostBookingsList({
    required this.userId,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('bookings')
        .where('hostId', isEqualTo: userId);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return FirestoreErrorView(error: snapshot.error);
        }

        final bookings = sortDocsByTime(snapshot.data?.docs ?? [], 'createdAt')
            .where((doc) {
          if (status == null) return true;
          final data = doc.data();
          return data is Map && data['status'] == status;
        }).toList();

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No bookings',
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
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final doc = bookings[index];
            final data = doc.data() as Map<String, dynamic>;
            return _BookingRequestCard(
              bookingId: doc.id,
              bookingData: data,
            );
          },
        );
      },
    );
  }
}

class _BookingRequestCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const _BookingRequestCard({
    required this.bookingId,
    required this.bookingData,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final petName = bookingData['petName'] as String? ?? 'Unknown';
    final renterName = bookingData['renterName'] as String? ?? 'Unknown';
    final startDate = bookingData['startDate'] as Timestamp?;
    final endDate = bookingData['endDate'] as Timestamp?;
    final totalDays = bookingData['totalDays'] as int? ?? 0;
    final totalPrice = bookingData['totalPrice'] as double?;
    final currency = bookingData['currency'] as String? ?? 'CAD';
    final status = bookingData['status'] as String? ?? 'pending';
    final paymentStatus = bookingData['paymentStatus'] as String? ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Renter: $renterName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'pending'
                        ? Colors.orange[100]
                        : status == 'confirmed'
                            ? Colors.green[100]
                            : status == 'completed'
                                ? Colors.blue[100]
                                : Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: status == 'pending'
                          ? Colors.orange[900]
                          : status == 'confirmed'
                              ? Colors.green[900]
                              : status == 'completed'
                                  ? Colors.blue[900]
                                  : Colors.red[900],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('Dates', '${_formatDate(startDate)} - ${_formatDate(endDate)}'),
            _buildDetailRow('Duration', '$totalDays ${totalDays == 1 ? 'day' : 'days'}'),
            if (totalPrice != null)
              _buildDetailRow('Total', '$currency${totalPrice.toStringAsFixed(2)}'),
            _buildDetailRow('Payment', paymentStatus.toUpperCase()),
            if (status == 'pending') ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectBooking(context, bookingId),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveBooking(context, bookingId),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'confirmed') ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final renterId = bookingData['renterId'] as String?;
                        final renterName = bookingData['renterName'] as String? ?? 'Unknown';
                        final renterEmail = bookingData['renterEmail'] as String?;
                        final petName = bookingData['petName'] as String?;
                        final petListingId = bookingData['petListingId'] as String?;

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          final conversationId = await createOrGetConversation(
                            userId1: user.uid,
                            userId2: renterId ?? '',
                            userName1: user.displayName ?? user.email?.split('@')[0] ?? 'Unknown',
                            userName2: renterName,
                            userEmail1: user.email,
                            userEmail2: renterEmail,
                            petListingId: petListingId,
                            petName: petName,
                            bookingId: bookingId,
                          );

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  conversationId: conversationId,
                                  otherUserId: renterId ?? '',
                                  otherUserName: renterName,
                                  otherUserEmail: renterEmail,
                                  petName: petName,
                                  petListingId: petListingId,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Message Renter'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveBooking(BuildContext context, String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'confirmed',
        'updatedAt': Timestamp.now(),
      });

      // Send notification
      final notificationService = NotificationService();
      await notificationService.notifyBookingStatusChanged(bookingId, 'confirmed');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(BuildContext context, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: const Text('Are you sure you want to reject this booking request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'cancelled',
          'cancelledAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Send notification
        final notificationService = NotificationService();
        await notificationService.notifyBookingStatusChanged(bookingId, 'cancelled');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking rejected'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _EarningsTab extends StatelessWidget {
  final String userId;

  const _EarningsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings Summary
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('hostId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              double totalEarnings = 0;
              double thisMonthEarnings = 0;
              int totalBookings = 0;

              if (snapshot.hasData) {
                final now = DateTime.now();
                final firstDayOfMonth = DateTime(now.year, now.month, 1);

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['paymentStatus'] != 'paid') continue;
                  final amount = (data['totalPrice'] as num?)?.toDouble() ?? 0;
                  totalEarnings += amount;
                  totalBookings++;

                  final createdAt = data['createdAt'] as Timestamp?;
                  if (createdAt != null) {
                    final createdDate = createdAt.toDate();
                    if (createdDate.isAfter(firstDayOfMonth)) {
                      thisMonthEarnings += amount;
                    }
                  }
                }
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black, Colors.grey[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Earnings',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CAD\$${totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'CAD\$${thisMonthEarnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'This Month',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white30,
                            ),
                            Column(
                              children: [
                                Text(
                                  '$totalBookings',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Total Bookings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent Transactions
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('hostId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              final paid = sortDocsByTime(snapshot.data!.docs, 'createdAt')
                  .where((doc) {
                final data = doc.data();
                return data is Map && data['paymentStatus'] == 'paid';
              }).take(10).toList();

              if (paid.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return Column(
                children: paid.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _EarningCard(bookingData: data);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const _EarningCard({required this.bookingData});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final petName = bookingData['petName'] as String? ?? 'Unknown';
    final renterName = bookingData['renterName'] as String? ?? 'Unknown';
    final totalPrice = bookingData['totalPrice'] as double? ?? 0.0;
    final currency = bookingData['currency'] as String? ?? 'CAD';
    final createdAt = bookingData['createdAt'] as Timestamp?;
    final platformFee = totalPrice * 0.10; // 10% platform fee
    final hostEarnings = totalPrice - platformFee;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Renter: $renterName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currency\$${hostEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Platform fee: $currency\$${platformFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

