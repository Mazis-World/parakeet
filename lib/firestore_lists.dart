import 'package:cloud_firestore/cloud_firestore.dart';

/// Milliseconds for a Firestore timestamp field. Missing values sort last
/// when the list is ordered newest first.
int firestoreTimeMillis(Object? value) {
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  return 0;
}

/// Newest document first, using [field] on each document.
List<QueryDocumentSnapshot> sortDocsByTime(
  Iterable<QueryDocumentSnapshot> docs,
  String field,
) {
  final sorted = docs.toList();
  sorted.sort((a, b) {
    final aData = a.data();
    final bData = b.data();
    final aTime = aData is Map ? aData[field] : null;
    final bTime = bData is Map ? bData[field] : null;
    return firestoreTimeMillis(bTime).compareTo(firestoreTimeMillis(aTime));
  });
  return sorted;
}
