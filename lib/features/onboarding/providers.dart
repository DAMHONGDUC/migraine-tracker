import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'presentation/controllers/onboarding_controller.dart';

/// Orchestrates onboarding: location permission + persisting the user's
/// choices (see [OnboardingController]).
final onboardingControllerProvider = Provider<OnboardingController>(
  OnboardingController.new,
);
