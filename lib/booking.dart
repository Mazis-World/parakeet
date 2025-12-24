import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parakeet/payments.dart';
import 'package:parakeet/notifications_service.dart';

class BookingScreen extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic> listingData;

  const BookingScreen({
    super.key,
    required this.listingId,
    required this.listingData,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  // Get pricing information
  double? get _dailyRate {
    final pricing = widget.listingData['pricing'] as Map<String, dynamic>?;
    return pricing?['dailyRate'] as double?;
  }

  double? get _weeklyRate {
    final pricing = widget.listingData['pricing'] as Map<String, dynamic>?;
    return pricing?['weeklyRate'] as double?;
  }

  String get _currency {
    final pricing = widget.listingData['pricing'] as Map<String, dynamic>?;
    return pricing?['currency'] as String? ?? 'CAD';
  }

  // Calculate total days
  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  // Calculate total price
  double? get _totalPrice {
    if (_startDate == null || _endDate == null) return null;
    if (_dailyRate == null && _weeklyRate == null) return null;

    final days = _totalDays;
    if (days <= 0) return null;

    // If weekly rate exists and rental is 7+ days, use weekly rate
    if (_weeklyRate != null && days >= 7) {
      final weeks = (days / 7).floor();
      final remainingDays = days % 7;
      return (weeks * _weeklyRate!) + (remainingDays * (_dailyRate ?? 0));
    }

    // Otherwise use daily rate
    return days * (_dailyRate ?? 0);
  }

  Future<void> _selectStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year, now.month, now.day); // Start of today
    final DateTime lastDate = firstDate.add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select start date',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before new start date, clear it
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first')),
      );
      return;
    }

    // Ensure start date is not in the past
    final DateTime now = DateTime.now();
    final DateTime startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final DateTime todayOnly = DateTime(now.year, now.month, now.day);
    final DateTime firstDate = startDateOnly.isBefore(todayOnly) 
        ? todayOnly.add(const Duration(days: 1))
        : _startDate!.add(const Duration(days: 1));
    final DateTime lastDate = firstDate.add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select end date',
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    if (_totalDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to make a booking')),
      );
      return;
    }

    // Check if user is trying to book their own pet
    final hostId = widget.listingData['hostId'] as String?;
    if (hostId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot book your own pet')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Validate pricing
      if (_totalPrice == null || _totalPrice! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid pricing: Please check listing rates')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Create booking document
      final bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
        'bookingId': '', // Will be updated after creation
        'petListingId': widget.listingId,
        'hostId': hostId,
        'hostName': widget.listingData['hostName'] as String? ?? 'Unknown',
        'hostEmail': widget.listingData['hostEmail'] as String?,
        'renterId': user.uid,
        'renterName': user.displayName ?? user.email?.split('@')[0] ?? 'Unknown',
        'renterEmail': user.email,
        'petName': widget.listingData['name'] as String? ?? 'Unknown',
        'petType': widget.listingData['animalType'] as String? ?? 'Unknown',
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'totalDays': _totalDays,
        'totalPrice': _totalPrice,
        'currency': _currency,
        'dailyRate': _dailyRate,
        'weeklyRate': _weeklyRate,
        'status': 'pending', // pending, confirmed, completed, cancelled
        'paymentStatus': 'pending', // pending, paid, refunded
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Update booking with its own ID
      await bookingRef.update({'bookingId': bookingRef.id});

      // Send notification
      await NotificationService().notifyBookingCreated(bookingRef.id);

      if (mounted) {
        // Navigate to payment screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              bookingId: bookingRef.id,
              totalAmount: _totalPrice ?? 0.0,
              currency: _currency,
              petName: widget.listingData['name'] as String? ?? 'Unknown',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting booking: $e'),
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

  @override
  Widget build(BuildContext context) {
    final petName = widget.listingData['name'] as String? ?? 'Unknown';
    final petType = widget.listingData['animalType'] as String? ?? 'Unknown';
    final images = widget.listingData['images'] as List<dynamic>? ?? [];
    final firstImage = images.isNotEmpty ? images[0] as String : null;

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
          'Request Booking',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    // Pet Image
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
                    // Pet Info
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
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Date Selection Section
              const Text(
                'Select Dates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Start Date
              InkWell(
                onTap: _selectStartDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.black),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _startDate != null
                                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                  : 'Select start date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _startDate != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _startDate != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // End Date
              InkWell(
                onTap: _selectEndDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.black),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'End Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _endDate != null
                                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                  : 'Select end date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _endDate != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _endDate != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Pricing Information
              if (_startDate != null && _endDate != null && _totalDays > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Total Days', '$_totalDays ${_totalDays == 1 ? 'day' : 'days'}'),
                      if (_dailyRate != null)
                        _buildSummaryRow('Daily Rate', '$_currency${_dailyRate!.toStringAsFixed(2)}'),
                      if (_weeklyRate != null && _totalDays >= 7)
                        _buildSummaryRow('Weekly Rate', '$_currency${_weeklyRate!.toStringAsFixed(2)}'),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        'Total Price',
                        '$_currency${_totalPrice?.toStringAsFixed(2) ?? '0.00'}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Rental Terms (if available)
              if (widget.listingData['rentalTerms'] != null) ...[
                const Text(
                  'Rental Terms',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.listingData['rentalTerms']?['minimumDays'] != null)
                        _buildInfoRow(
                          'Minimum Days',
                          '${widget.listingData['rentalTerms']?['minimumDays']}',
                        ),
                      if (widget.listingData['rentalTerms']?['maximumDays'] != null)
                        _buildInfoRow(
                          'Maximum Days',
                          '${widget.listingData['rentalTerms']?['maximumDays']}',
                        ),
                      if (widget.listingData['rentalTerms']?['cancellationPolicy'] != null)
                        _buildInfoRow(
                          'Cancellation Policy',
                          widget.listingData['rentalTerms']?['cancellationPolicy'] as String,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
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
                          'Submit Booking Request',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your booking request will be sent to the host for approval.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

