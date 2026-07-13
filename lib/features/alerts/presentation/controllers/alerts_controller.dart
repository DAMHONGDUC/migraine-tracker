import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../../domain/entities/alerts_settings.dart';
import '../../providers.dart';

/// Owns the alerts toggle + threshold. Local prefs are the source of truth
/// for the UI; the Firestore registration is a side effect of the actions
/// so the whole screen keeps working offline (errors just surface).
class AlertsController extends AsyncNotifier<AlertsSettings> {
  static const enabledKey = 'alerts_enabled';

  @override
  AlertsSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AlertsSettings(
      enabled: prefs.getBool(enabledKey) ?? false,
      thresholdHpa:
          prefs.getDouble(OnboardingController.thresholdKey) ?? 5,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.requireValue;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(alertRegistrationRepositoryProvider);
      if (enabled) {
        await repo.register(thresholdHpa: current.thresholdHpa);
      } else {
        await repo.unregister();
      }
      await ref
          .read(sharedPreferencesProvider)
          .setBool(enabledKey, enabled);
      return current.copyWith(enabled: enabled);
    });
  }

  Future<void> setThreshold(double thresholdHpa) async {
    final current = state.requireValue;
    await ref
        .read(sharedPreferencesProvider)
        .setDouble(OnboardingController.thresholdKey, thresholdHpa);
    if (current.enabled) {
      await ref
          .read(alertRegistrationRepositoryProvider)
          .updateThreshold(thresholdHpa);
    }
    state = AsyncData(current.copyWith(thresholdHpa: thresholdHpa));
  }
}

final alertsControllerProvider =
    AsyncNotifierProvider<AlertsController, AlertsSettings>(
      AlertsController.new,
    );
