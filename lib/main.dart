import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'bare_ease_app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/storage/secure_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SecureStore store = await AppBootstrap.init();

  runApp(
    ProviderScope(
      overrides: [secureStoreProvider.overrideWithValue(store)],
      child: const BaroEaseApp(),
    ),
  );
}
