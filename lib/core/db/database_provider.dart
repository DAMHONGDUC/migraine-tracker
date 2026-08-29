import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app_database.dart';

/// Single app-wide database instance. Override with an in-memory database in tests.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
