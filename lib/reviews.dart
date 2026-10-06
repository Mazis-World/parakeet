import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:parakeet/firestore_errors.dart';

class ReviewScreen extends StatefulWidget {
  final String bookingId;
  final String petListingId;
  final String hostId;
  final String petName;
  final bool isHostReviewingRenter;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.petListingId,
    required this.hostId,
    required this.petName,
    this.isHostReviewingRenter = false,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review comment')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final renterId = widget.isHostReviewingRenter
          ? await _getRenterIdFromBooking()
          : user.uid;
      final hostId = widget.isHostReviewingRenter
          ? user.uid
          : widget.hostId;

      // Check if review already exists
      final existingReview = await FirebaseFirestore.instance
          .collection('reviews')
          .where('bookingId', isEqualTo: widget.bookingId)
          .where(widget.isHostReviewingRenter ? 'hostId' : 'renterId',
              isEqualTo: user.uid)
          .get();

      if (existingReview.docs.isNotEmpty) {
        // Update existing review
        await existingReview.docs.first.reference.update({
          'rating': _rating,
          'comment': _commentController.text.trim(),
          'updatedAt': Timestamp.now(),
        });
      } else {
        // Create new review
        final reviewRef = await FirebaseFirestore.instance
            .collection('reviews')
            .add({
          'reviewId': '',
          'bookingId': widget.bookingId,
          'petListingId': widget.petListingId,
          'hostId': hostId,
          'renterId': renterId,
          'renterName': widget.isHostReviewingRenter
              ? (await _getRenterNameFromBooking())
              : (user.displayName ?? user.email?.split('@')[0] ?? 'Unknown'),
          'renterProfileImage': user.photoURL,
          'rating': _rating,
          'comment': _commentController.text.trim(),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        await reviewRef.update({'reviewId': reviewRef.id});
      }

      // Update listing rating
      await _updateListingRating();

      // Update user stats
      await _updateUserStats(hostId, renterId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String> _getRenterIdFromBooking() async {
    final booking = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .get();
    return booking.data()?['renterId'] as String? ?? '';
  }

  Future<String> _getRenterNameFromBooking() async {
    final booking = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .get();
    return booking.data()?['renterName'] as String? ?? 'Unknown';
  }

  Future<void> _updateListingRating() async {
    final reviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('petListingId', isEqualTo: widget.petListingId)
        .get();

    if (reviews.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in reviews.docs) {
      totalRating += (doc.data()['rating'] as int? ?? 0).toDouble();
    }

    final averageRating = totalRating / reviews.docs.length;

    await FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.petListingId)
        .update({
      'rating': averageRating,
      'reviewCount': reviews.docs.length,
    });
  }

  Future<void> _updateUserStats(String hostId, String renterId) async {
    // Update host stats
    final hostReviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('hostId', isEqualTo: hostId)
        .get();

    if (hostReviews.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in hostReviews.docs) {
        totalRating += (doc.data()['rating'] as int? ?? 0).toDouble();
      }
      final averageRating = totalRating / hostReviews.docs.length;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(hostId)
          .set({
        'hostStats': {
          'averageRating': averageRating,
          'totalReviews': hostReviews.docs.length,
        },
      }, SetOptions(merge: true));
    }

    // Update renter stats
    final renterReviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('renterId', isEqualTo: renterId)
        .get();

    if (renterReviews.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in renterReviews.docs) {
        totalRating += (doc.data()['rating'] as int? ?? 0).toDouble();
      }
      final averageRating = totalRating / renterReviews.docs.length;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(renterId)
          .set({
        'renterStats': {
          'averageRating': averageRating,
          'totalReviews': renterReviews.docs.length,
        },
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isHostReviewingRenter
              ? 'Review Renter'
              : 'Review ${widget.petName}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Rating Stars
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 48,
                      color: index < _rating ? Colors.amber : Colors.grey,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _rating == 1
                    ? 'Poor'
                    : _rating == 2
                        ? 'Fair'
                        : _rating == 3
                            ? 'Good'
                            : _rating == 4
                                ? 'Very Good'
                                : 'Excellent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Comment Field
            const Text(
              'Tell us more about your experience',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reviews List Widget
class ReviewsList extends StatelessWidget {
  final String petListingId;
  final int? limit;

  const ReviewsList({
    super.key,
    required this.petListingId,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('reviews')
        .where('petListingId', isEqualTo: petListingId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit!);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
              children: [
                Icon(Icons.reviews, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ReviewCard(reviewData: data);
          }).toList(),
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

