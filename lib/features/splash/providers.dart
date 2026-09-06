import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'presentation/controllers/splash_controller.dart';

final splashControllerProvider = Provider<SplashController>(
  (ref) => const SplashController(),
);
