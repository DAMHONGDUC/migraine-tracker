import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/last_alert_repository.dart';
import '../../domain/services/pressure_alert_mapper.dart';

/// Reads the `lastAlert*` fields the cron writes on `users/{uid}` after every push, so a missed alert can be rebuilt as a list row.
class FirestoreLastAlertRepository implements LastAlertRepository {
  const FirestoreLastAlertRepository(this._auth, this._firestore);

  static const String collectionPath = 'users';
  static const String atField = 'lastAlertAt';
  static const String eventIdField = 'lastAlertEventId';
  static const String dropHpaField = 'lastAlertDropHpa';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// The doc holds only the LATEST alert, so this catches up one alert, not a backlog.
  @override
  Future<AppNotification?> latest() async {
    final User? user = _auth.currentUser;

    if (user == null) return null;
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(collectionPath)
        .doc(user.uid)
        .get();
    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) return null;
    final Object? at = data[atField];

    return PressureAlertMapper.fromRecord(
      eventId: data[eventIdField],
      occurredAt: at is Timestamp ? at.toDate() : null,
      dropHpa: data[dropHpaField],
    );
  }
}
