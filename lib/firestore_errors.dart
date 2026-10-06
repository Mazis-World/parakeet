import 'package:flutter/material.dart';

/// True when Cloud Firestore rejected the call with permission-denied.
bool isFirestorePermissionDenied(Object? error) {
  final text = error.toString().toLowerCase();
  return text.contains('permission-denied') ||
      text.contains('insufficient permissions') ||
      text.contains('missing or insufficient');
}

/// Replaces the raw `[cloud_firestore/permission-denied]` string with the
/// step that actually clears it: publishing [firestore.rules].
class FirestoreErrorView extends StatelessWidget {
  final Object? error;

  const FirestoreErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    if (!isFirestorePermissionDenied(error)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              'Firestore blocked this request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your Firebase project is still using rules that deny every read and write. '
              'In the Firebase console open Firestore Database, then Rules, paste the contents of firestore.rules from this project, and publish. '
              'Do the same for Storage with storage.rules if photo uploads fail.',
              style:
                  TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
