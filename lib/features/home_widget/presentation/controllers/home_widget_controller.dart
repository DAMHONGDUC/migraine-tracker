import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/locale_utils.dart';
import '../../../../core/utils/signed_number_utils.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';
import '../../../weather/domain/entities/daily_pressure.dart';
import '../../../weather/providers.dart';
import '../../domain/entities/home_widget_content.dart';
import '../../domain/entities/home_widget_snapshot.dart';
import '../../domain/repositories/home_widget_repository.dart';
import '../../providers.dart';

/// Owns the home-screen widget's on/off flag and every write to it.
///
/// State is the flag alone. Everything else the widget shows is derived on
/// demand — there is no second copy of the week count or the pressure living
/// in here to fall out of step with the database.
class HomeWidgetController extends Notifier<bool> {
  @override
  /// On by default. Adding the widget is itself the opt-in — iOS has no API
  /// for placing one, so nothing is published anywhere the user did not put
  /// it — and defaulting the feed off would show dashes on a widget they just
  /// added, with the fix two taps away in Settings.
  bool build() =>
      ref
          .watch(sharedPreferencesProvider)
          .getBool(PrefsKeyConstant.homeWidgetEnabled) ??
      true;

  /// The Settings switch. Turning it off empties the shared container rather
  /// than just stopping the writes — a widget left showing last week's count
  /// forever is worse than an empty one.
  Future<void> setEnabled(bool enabled) async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final HomeWidgetRepository widget = ref.read(homeWidgetRepositoryProvider);

    try {
      await prefs.setBool(PrefsKeyConstant.homeWidgetEnabled, enabled);
      state = enabled;

      if (enabled) {
        await refresh();
      } else {
        await widget.clear();
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Home widget toggle failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Redraws the widget from what the app currently holds.
  ///
  /// Called on launch, on resume, whenever the attack list changes and
  /// whenever the language does. Cheap enough to run on all four: one query
  /// for the attacks, one row for the pressure, no network at all — the
  /// reading is whatever `DailyPressureRecorder` last stored.
  Future<void> refresh() async {
    final HomeWidgetRepository widget = ref.read(homeWidgetRepositoryProvider);

    if (!state || !widget.isSupported) return;

    try {
      final List<Attack> attacks = await ref
          .read(attackRepositoryProvider)
          .getAll();
      final DailyPressure? pressure = await ref
          .read(dailyPressureRepositoryProvider)
          .latest();
      final HomeWidgetSnapshot snapshot = ref
          .read(homeWidgetSnapshotBuilderProvider)
          .build(attacks: attacks, pressure: pressure, now: DateTime.now());

      await widget.publish(_word(snapshot));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Home widget refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// The GDPR wipe's share of the work (hard rule 8): the App Group holds a
  /// week count and a pressure reading, which are the user's data wherever
  /// they happen to sit.
  Future<void> clear() => ref.read(homeWidgetRepositoryProvider).clear();

  /// Renders the snapshot in the user's language.
  ///
  /// There is no `BuildContext` on any of the paths that call [refresh] —
  /// launch, resume, a provider listener — so the locale is resolved the same
  /// way a background-scheduled reminder resolves it.
  HomeWidgetContent _word(HomeWidgetSnapshot snapshot) {
    final Locale locale = LocaleUtils.resolve(
      chosen: ref.read(localeControllerProvider),
      platform: PlatformDispatcher.instance.locale,
      supported: AppLocalizations.supportedLocales,
    );
    final AppLocalizations l10n = lookupAppLocalizations(locale);
    final DateTime? expiresAt = snapshot.pressureExpiresAt;

    return HomeWidgetContent(
      logLabel: l10n.homeWidgetLogLabel,
      weekLabel: l10n.homeWidgetWeekLabel,
      weekValue: l10n.homeWidgetWeekValue(snapshot.weekCount),
      pressureLabel: l10n.homeWidgetPressureLabel,
      // No decimal: the widget has one line for it, and 1 hPa of precision is
      // more than a glance can use.
      pressureValue: snapshot.hasPressure
          ? l10n.homeWidgetPressureValue(
              snapshot.pressureHpa!.toStringAsFixed(0),
            )
          : l10n.homeWidgetPressureNone,
      pressureDetail: snapshot.hasPressure
          ? l10n.homeWidgetPressureDetail(
              SignedNumberUtils.format(snapshot.pressureDelta24hHpa!),
            )
          : '',
      pressureExpiresAtEpochSeconds: expiresAt == null
          ? ''
          : '${expiresAt.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond}',
      // Only when a reading is actually drawn — attributing a blank is noise,
      // and the widget blanks itself once the reading expires.
      attribution: snapshot.hasPressure ? l10n.weatherAttribution : '',
      trend: snapshot.trend,
    );
  }
}
