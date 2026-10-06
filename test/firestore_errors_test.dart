import 'package:flutter_test/flutter_test.dart';
import 'package:parakeet/firestore_errors.dart';

void main() {
  test('detects Cloud Firestore permission-denied errors', () {
    expect(
      isFirestorePermissionDenied(
        Exception(
          '[cloud_firestore/permission-denied] Missing or insufficient permissions.',
        ),
      ),
      isTrue,
    );
    expect(
      isFirestorePermissionDenied(
          Exception('SocketException: failed host lookup')),
      isFalse,
    );
  });
}
