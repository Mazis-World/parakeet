import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parakeet/firestore_lists.dart';

void main() {
  test('orders timestamps newest first and treats a missing time as oldest', () {
    final older = Timestamp.fromDate(DateTime.utc(2026, 1, 1));
    final newer = Timestamp.fromDate(DateTime.utc(2026, 6, 1));

    expect(firestoreTimeMillis(newer) > firestoreTimeMillis(older), isTrue);
    expect(firestoreTimeMillis(null), 0);
    expect(
      firestoreTimeMillis(newer).compareTo(firestoreTimeMillis(older)),
      greaterThan(0),
    );
  });
}