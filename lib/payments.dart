import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:parakeet/notifications_service.dart';

// NOTE: In production, you'll need a backend server to securely handle Stripe API keys
// This is a simplified implementation for MVP
// Replace with your backend URL
const String backendUrl = 'YOUR_BACKEND_URL'; // e.g., 'https://your-api.com'

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double totalAmount;
  final String currency;
  final String petName;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.totalAmount,
    required this.currency,
    required this.petName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _cardholderNameController = TextEditingController();
  
  bool _isProcessing = false;
  String? _errorMessage;

  // Platform fee (10% of booking total)
  double get _platformFee => widget.totalAmount * 0.10;
  
  // Service fee (5% of booking total)
  double get _serviceFee => widget.totalAmount * 0.05;
  
  // Total amount including fees
  double get _totalWithFees => widget.totalAmount + _platformFee + _serviceFee;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    // Validate all fields
    if (_cardNumberController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvcController.text.isEmpty ||
        _cardholderNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all payment details';
      });
      return;
    }

    // Validate card number (basic check - should be 13-19 digits)
    final cardNumber = _cardNumberController.text.replaceAll(RegExp(r'\s+'), '');
    if (cardNumber.length < 13 || cardNumber.length > 19 || !RegExp(r'^\d+$').hasMatch(cardNumber)) {
      setState(() {
        _errorMessage = 'Please enter a valid card number';
      });
      return;
    }

    // Validate expiry date (MM/YY format)
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_expiryController.text)) {
      setState(() {
        _errorMessage = 'Please enter expiry date in MM/YY format';
      });
      return;
    }

    // Validate CVC (3-4 digits)
    if (!RegExp(r'^\d{3,4}$').hasMatch(_cvcController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid CVC';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // In production, create payment intent on your backend
      // For MVP, we'll simulate the payment flow
      // TODO: Replace with actual Stripe payment intent creation via backend
      
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Create payment record in Firestore
      final paymentRef = await FirebaseFirestore.instance.collection('payments').add({
        'paymentId': '',
        'bookingId': widget.bookingId,
        'userId': user.uid,
        'amount': widget.totalAmount,
        'platformFee': _platformFee,
        'serviceFee': _serviceFee,
        'totalAmount': _totalWithFees,
        'currency': widget.currency,
        'status': 'completed', // In production, this would come from Stripe webhook
        'paymentMethod': 'card',
        'paymentIntentId': 'pi_simulated_${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': Timestamp.now(),
      });

      await paymentRef.update({'paymentId': paymentRef.id});

      // Update booking payment status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'paymentStatus': 'paid',
        'paymentIntentId': 'pi_simulated_${DateTime.now().millisecondsSinceEpoch}',
        'updatedAt': Timestamp.now(),
      });

      // Create transaction record
      await FirebaseFirestore.instance.collection('transactions').add({
        'transactionId': '',
        'userId': user.uid,
        'bookingId': widget.bookingId,
        'type': 'payment',
        'amount': _totalWithFees,
        'currency': widget.currency,
        'status': 'completed',
        'description': 'Payment for ${widget.petName} booking',
        'createdAt': Timestamp.now(),
      });

      // Send payment notification
      await NotificationService().notifyPaymentReceived(widget.bookingId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(
              bookingId: widget.bookingId,
              amount: _totalWithFees,
              currency: widget.currency,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment failed: $e';
      });
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
        title: const Text(
          'Payment',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
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
                  const SizedBox(height: 12),
                  _buildSummaryRow('Pet', widget.petName),
                  _buildSummaryRow('Booking Total', '${widget.currency}${widget.totalAmount.toStringAsFixed(2)}'),
                  _buildSummaryRow('Platform Fee (10%)', '${widget.currency}${_platformFee.toStringAsFixed(2)}'),
                  _buildSummaryRow('Service Fee (5%)', '${widget.currency}${_serviceFee.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Total',
                    '${widget.currency}${_totalWithFees.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Form
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Cardholder Name
            TextField(
              controller: _cardholderNameController,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            // Card Number
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.credit_card),
              ),
              maxLength: 19,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                // Expiry Date
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'MM/YY',
                      hintText: '12/24',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    maxLength: 5,
                  ),
                ),
                const SizedBox(width: 16),
                // CVC
                Expanded(
                  child: TextField(
                    controller: _cvcController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'CVC',
                      hintText: '123',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    maxLength: 4,
                  ),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Security Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment is secured with industry-standard encryption',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Pay ${widget.currency}${_totalWithFees.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Card Info (for development)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use test card: 4242 4242 4242 4242\nExpiry: Any future date\nCVC: Any 3 digits',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentConfirmationScreen extends StatelessWidget {
  final String bookingId;
  final double amount;
  final String currency;

  const PaymentConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your payment of $currency${amount.toStringAsFixed(2)} has been processed successfully.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view transactions'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user.uid)
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
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
              return _TransactionCard(transactionData: data);
            },
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transactionData;

  const _TransactionCard({required this.transactionData});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final type = transactionData['type'] as String? ?? 'payment';
    final amount = transactionData['amount'] as double? ?? 0.0;
    final currency = transactionData['currency'] as String? ?? 'CAD';
    final status = transactionData['status'] as String? ?? 'pending';
    final description = transactionData['description'] as String? ?? 'Transaction';
    final createdAt = transactionData['createdAt'] as Timestamp?;

    final isPayment = type == 'payment';
    final isCompleted = status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPayment ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPayment ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPayment ? Colors.red[700] : Colors.green[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green[900] : Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isPayment ? '-' : '+'}$currency${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isPayment ? Colors.red[700] : Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

