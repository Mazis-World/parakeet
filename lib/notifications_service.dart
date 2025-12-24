import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Notification Service
/// 
/// This service handles sending notifications for various events.
/// For production, integrate with:
/// - Firebase Cloud Messaging (FCM) for push notifications
/// - SendGrid or Firebase Extensions for email notifications
/// - Firebase Cloud Functions for backend processing
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Check if user has notifications enabled
  Future<bool> _shouldNotify(String userId, String notificationType) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return true; // Default to enabled

      final data = userDoc.data() as Map<String, dynamic>?;
      final notifications = data?['notifications'] as Map<String, dynamic>?;

      if (notifications == null) return true; // Default to enabled

      // Check general notification settings
      final emailEnabled = notifications['email'] as bool? ?? true;
      final pushEnabled = notifications['push'] as bool? ?? true;

      // Check specific notification type
      final typeEnabled = notifications[notificationType] as bool? ?? true;

      return (emailEnabled || pushEnabled) && typeEnabled;
    } catch (e) {
      return true; // Default to enabled on error
    }
  }

  /// Send booking notification
  Future<void> notifyBookingCreated(String bookingId) async {
    try {
      final booking = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!booking.exists) return;

      final data = booking.data() as Map<String, dynamic>;
      final hostId = data['hostId'] as String?;
      final renterId = data['renterId'] as String?;
      final petName = data['petName'] as String? ?? 'Unknown';

      // Notify host
      if (hostId != null) {
        final shouldNotify = await _shouldNotify(hostId, 'booking');
        if (shouldNotify) {
          await _createNotification(
            userId: hostId,
            type: 'booking_request',
            title: 'New Booking Request',
            message: 'You have a new booking request for $petName',
            bookingId: bookingId,
          );
        }
      }

      // Notify renter
      if (renterId != null) {
        final shouldNotify = await _shouldNotify(renterId, 'booking');
        if (shouldNotify) {
          await _createNotification(
            userId: renterId,
            type: 'booking_confirmed',
            title: 'Booking Request Sent',
            message: 'Your booking request for $petName has been sent',
            bookingId: bookingId,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Send booking status change notification
  Future<void> notifyBookingStatusChanged(
    String bookingId,
    String newStatus,
  ) async {
    try {
      final booking = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!booking.exists) return;

      final data = booking.data() as Map<String, dynamic>;
      final hostId = data['hostId'] as String?;
      final renterId = data['renterId'] as String?;
      final petName = data['petName'] as String? ?? 'Unknown';

      String title;
      String message;
      String? notifyUserId;

      switch (newStatus) {
        case 'confirmed':
          title = 'Booking Confirmed';
          message = 'Your booking for $petName has been confirmed';
          notifyUserId = renterId;
          break;
        case 'cancelled':
          title = 'Booking Cancelled';
          message = 'Booking for $petName has been cancelled';
          notifyUserId = renterId ?? hostId;
          break;
        case 'completed':
          title = 'Booking Completed';
          message = 'Your booking for $petName has been completed';
          notifyUserId = renterId;
          break;
        default:
          return;
      }

      if (notifyUserId != null) {
        final shouldNotify = await _shouldNotify(notifyUserId, 'booking');
        if (shouldNotify) {
          await _createNotification(
            userId: notifyUserId,
            type: 'booking_status',
            title: title,
            message: message,
            bookingId: bookingId,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Send message notification
  Future<void> notifyNewMessage(
    String conversationId,
    String senderId,
    String receiverId,
    String messageText,
  ) async {
    try {
      final shouldNotify = await _shouldNotify(receiverId, 'message');
      if (!shouldNotify) return;

      await _createNotification(
        userId: receiverId,
        type: 'message',
        title: 'New Message',
        message: messageText.length > 50
            ? '${messageText.substring(0, 50)}...'
            : messageText,
        conversationId: conversationId,
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Send payment notification
  Future<void> notifyPaymentReceived(String bookingId) async {
    try {
      final booking = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!booking.exists) return;

      final data = booking.data() as Map<String, dynamic>;
      final hostId = data['hostId'] as String?;
      final renterId = data['renterId'] as String?;
      final totalPrice = data['totalPrice'] as double?;
      final currency = data['currency'] as String? ?? 'CAD';

      // Notify host
      if (hostId != null) {
        final shouldNotify = await _shouldNotify(hostId, 'booking');
        if (shouldNotify) {
          await _createNotification(
            userId: hostId,
            type: 'payment_received',
            title: 'Payment Received',
            message: 'Payment of $currency\$${totalPrice?.toStringAsFixed(2) ?? '0.00'} received',
            bookingId: bookingId,
          );
        }
      }

      // Notify renter
      if (renterId != null) {
        final shouldNotify = await _shouldNotify(renterId, 'booking');
        if (shouldNotify) {
          await _createNotification(
            userId: renterId,
            type: 'payment_confirmed',
            title: 'Payment Confirmed',
            message: 'Your payment has been processed successfully',
            bookingId: bookingId,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Create notification document in Firestore
  Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? bookingId,
    String? conversationId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': type,
        'title': title,
        'message': message,
        'bookingId': bookingId,
        'conversationId': conversationId,
        'read': false,
        'createdAt': Timestamp.now(),
      });

      // TODO: In production, also send:
      // - Push notification via FCM
      // - Email notification via SendGrid/Firebase Extensions
    } catch (e) {
      // Handle error silently
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      // Handle error silently
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

