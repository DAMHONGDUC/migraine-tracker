import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/bootstrap/app_bootstrap_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Straight to a frame: bootstrap runs under the splash rather than in front of a launch screen nobody can tell from a hang.
  runApp(const ProviderScope(child: AppBootstrapGate()));
}
