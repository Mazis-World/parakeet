import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AvailabilityCalendarScreen extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic>? listingData;

  const AvailabilityCalendarScreen({
    super.key,
    required this.listingId,
    this.listingData,
  });

  @override
  State<AvailabilityCalendarScreen> createState() => _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState extends State<AvailabilityCalendarScreen> {
  DateTime _selectedMonth = DateTime.now();
  Set<DateTime> _blockedDates = {};
  Set<DateTime> _bookedDates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    _loadBookings();
  }

  Future<void> _loadAvailability() async {
    try {
      final listing = await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .get();

      if (listing.exists) {
        final data = listing.data() as Map<String, dynamic>;
        final availability = data['availability'] as Map<String, dynamic>?;
        final blockedDates = availability?['blockedDates'] as List<dynamic>?;

        if (blockedDates != null) {
          setState(() {
            _blockedDates = blockedDates
                .map((timestamp) => (timestamp as Timestamp).toDate())
                .toSet();
          });
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('petListingId', isEqualTo: widget.listingId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final bookedDates = <DateTime>{};
      for (var doc in bookings.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final startDate = (data['startDate'] as Timestamp?)?.toDate();
        final endDate = (data['endDate'] as Timestamp?)?.toDate();

        if (startDate != null && endDate != null) {
          var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
          final end = DateTime(endDate.year, endDate.month, endDate.day);

          while (!currentDate.isAfter(end)) {
            bookedDates.add(currentDate);
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }
      }

      setState(() {
        _bookedDates = bookedDates;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _toggleDateAvailability(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Don't allow blocking past dates
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (dateOnly.isBefore(todayOnly)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot modify past dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Don't allow blocking booked dates
    if (_bookedDates.contains(dateOnly)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot block dates with existing bookings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Optimistic update
    final wasBlocked = _blockedDates.contains(dateOnly);
    setState(() {
      if (wasBlocked) {
        _blockedDates.remove(dateOnly);
      } else {
        _blockedDates.add(dateOnly);
      }
    });

    try {
      final blockedTimestamps = _blockedDates.map((date) => Timestamp.fromDate(date)).toList();

      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .set({
        'availability': {
          'blockedDates': blockedTimestamps,
          'updatedAt': Timestamp.now(),
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasBlocked ? 'Date unblocked' : 'Date blocked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        if (wasBlocked) {
          _blockedDates.add(dateOnly);
        } else {
          _blockedDates.remove(dateOnly);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _blockDateRange() async {
    final startDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (startDate == null) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (endDate == null) return;

    final datesToBlock = <DateTime>{};
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!currentDate.isAfter(end)) {
      if (!_bookedDates.contains(currentDate)) {
        datesToBlock.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    setState(() {
      _blockedDates.addAll(datesToBlock);
    });

    try {
      final blockedTimestamps = _blockedDates.map((date) => Timestamp.fromDate(date)).toList();

      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .set({
        'availability': {
          'blockedDates': blockedTimestamps,
          'updatedAt': Timestamp.now(),
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Date range blocked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingName = widget.listingData?['name'] as String? ?? 'Pet Listing';

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
          'Availability: $listingName',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_busy, color: Colors.black),
            onPressed: _blockDateRange,
            tooltip: 'Block Date Range',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Legend
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
                          'Legend',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LegendItem(
                          color: Colors.green,
                          label: 'Available',
                        ),
                        _LegendItem(
                          color: Colors.red,
                          label: 'Blocked',
                        ),
                        _LegendItem(
                          color: Colors.orange,
                          label: 'Booked',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Calendar
                  _buildCalendar(),
                  const SizedBox(height: 24),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'How to use',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Tap a date to block/unblock it\n'
                          '• Use "Block Date Range" to block multiple dates\n'
                          '• Booked dates cannot be blocked',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[900],
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

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return Column(
      children: [
        // Month Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Weekday Headers
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar Grid
        ...List.generate(
          ((firstDayWeekday - 1) + daysInMonth + 6) ~/ 7,
          (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - (firstDayWeekday - 1) + 1;
                
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                final dateOnly = DateTime(date.year, date.month, date.day);
                final isPast = dateOnly.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                final isBlocked = _blockedDates.contains(dateOnly);
                final isBooked = _bookedDates.contains(dateOnly);

                Color backgroundColor;
                Color textColor = Colors.black;

                if (isPast) {
                  backgroundColor = Colors.grey[200]!;
                  textColor = Colors.grey[400]!;
                } else if (isBooked) {
                  backgroundColor = Colors.orange[100]!;
                  textColor = Colors.orange[900]!;
                } else if (isBlocked) {
                  backgroundColor = Colors.red[100]!;
                  textColor = Colors.red[900]!;
                } else {
                  backgroundColor = Colors.green[100]!;
                  textColor = Colors.green[900]!;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: InkWell(
                      onTap: isPast || isBooked
                          ? null
                          : () => _toggleDateAvailability(date),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPast ? Colors.grey[300]! : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

