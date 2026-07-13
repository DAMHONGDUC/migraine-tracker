import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../weather/providers.dart';
import 'data/repositories/firebase_alert_registration_repository.dart';
import 'domain/repositories/alert_registration_repository.dart';

/// Only read inside controller actions (never watched at build time) so
/// screens and tests don't touch Firebase until the user flips the toggle.
final alertRegistrationRepositoryProvider =
    Provider<AlertRegistrationRepository>(
      (ref) => FirebaseAlertRegistrationRepository(
        FirebaseAuth.instance,
        FirebaseMessaging.instance,
        FirebaseFirestore.instance,
        ref.watch(locationSourceProvider),
      ),
    );
