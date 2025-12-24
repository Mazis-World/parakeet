import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:parakeet/messaging.dart';
import 'package:parakeet/reviews.dart';
import 'package:parakeet/payments.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view your bookings'),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'My Bookings',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingsList(status: 'pending', userId: user.uid),
            _BookingsList(status: 'confirmed', userId: user.uid),
            _BookingsList(status: 'completed', userId: user.uid, includeCancelled: true),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final String status;
  final String userId;
  final bool includeCancelled;

  const _BookingsList({
    required this.status,
    required this.userId,
    this.includeCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('renterId', isEqualTo: userId);

    if (status == 'completed') {
      if (includeCancelled) {
        query = query.where('status', whereIn: ['completed', 'cancelled']);
      } else {
        query = query.where('status', isEqualTo: 'completed');
      }
    } else {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No $status bookings',
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
            return _BookingCard(bookingId: doc.id, bookingData: data);
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const _BookingCard({
    required this.bookingId,
    required this.bookingData,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'green';
      case 'completed':
        return 'blue';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  @override
  Widget build(BuildContext context) {
    final petName = bookingData['petName'] as String? ?? 'Unknown';
    final petType = bookingData['petType'] as String? ?? 'Unknown';
    final hostName = bookingData['hostName'] as String? ?? 'Unknown';
    final startDate = bookingData['startDate'] as Timestamp?;
    final endDate = bookingData['endDate'] as Timestamp?;
    final totalDays = bookingData['totalDays'] as int? ?? 0;
    final totalPrice = bookingData['totalPrice'] as double?;
    final currency = bookingData['currency'] as String? ?? 'CAD';
    final status = bookingData['status'] as String? ?? 'pending';
    final paymentStatus = bookingData['paymentStatus'] as String? ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        petType,
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
                    color: _getStatusColor(status) == 'orange'
                        ? Colors.orange[100]
                        : _getStatusColor(status) == 'green'
                            ? Colors.green[100]
                            : _getStatusColor(status) == 'blue'
                                ? Colors.blue[100]
                                : Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status) == 'orange'
                          ? Colors.orange[900]
                          : _getStatusColor(status) == 'green'
                              ? Colors.green[900]
                              : _getStatusColor(status) == 'blue'
                                  ? Colors.blue[900]
                                  : Colors.red[900],
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Booking Details
            _buildDetailRow(Icons.person, 'Host', hostName),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              'Dates',
              '${_formatDate(startDate)} - ${_formatDate(endDate)}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.access_time,
              'Duration',
              '$totalDays ${totalDays == 1 ? 'day' : 'days'}',
            ),
            if (totalPrice != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.attach_money,
                'Total Price',
                '$currency${totalPrice.toStringAsFixed(2)}',
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.payment,
              'Payment Status',
              paymentStatus.toUpperCase(),
            ),

            // Action Buttons
            if (status == 'pending') ...[
              const Divider(height: 24),
              if (paymentStatus == 'pending') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final totalPrice = bookingData['totalPrice'] as double? ?? 0.0;
                      final currency = bookingData['currency'] as String? ?? 'CAD';
                      final petName = bookingData['petName'] as String? ?? 'Unknown';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            bookingId: bookingId,
                            totalAmount: totalPrice,
                            currency: currency,
                            petName: petName,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                    ),
                    child: const Text('Pay Now'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _cancelBooking(context, bookingId);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],

            if (status == 'completed') ...[
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final petListingId = bookingData['petListingId'] as String? ?? '';
                    final hostId = bookingData['hostId'] as String? ?? '';
                    final petName = bookingData['petName'] as String? ?? 'Unknown';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewScreen(
                          bookingId: bookingId,
                          petListingId: petListingId,
                          hostId: hostId,
                          petName: petName,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                  ),
                  child: const Text('Leave Review'),
                ),
              ),
            ],

            if (status == 'confirmed') ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final hostId = bookingData['hostId'] as String?;
                        final hostName = bookingData['hostName'] as String? ?? 'Unknown';
                        final hostEmail = bookingData['hostEmail'] as String?;
                        final petName = bookingData['petName'] as String?;
                        final petListingId = bookingData['petListingId'] as String?;
                        final currentBookingId = bookingId;

                        try {
                          final conversationId = await createOrGetConversation(
                            userId1: user.uid,
                            userId2: hostId ?? '',
                            userName1: user.displayName ?? user.email?.split('@')[0] ?? 'Unknown',
                            userName2: hostName,
                            userEmail1: user.email,
                            userEmail2: hostEmail,
                            petListingId: petListingId,
                            petName: petName,
                            bookingId: currentBookingId,
                          );

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  conversationId: conversationId,
                                  otherUserId: hostId ?? '',
                                  otherUserName: hostName,
                                  otherUserEmail: hostEmail,
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
                                content: Text('Error starting conversation: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Contact Host'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _cancelBooking(context, bookingId);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancel'),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
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
    );
  }

  Future<void> _cancelBooking(BuildContext context, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
          'status': 'cancelled',
          'cancelledAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

