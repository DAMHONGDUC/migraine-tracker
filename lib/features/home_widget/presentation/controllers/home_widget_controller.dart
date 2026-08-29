import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/l10n/locale_provider.dart';
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
class HomeWidgetController extends Notifier<bool> {
  @override
  /// On by default.
  bool build() =>
      ref
          .watch(sharedPreferencesProvider)
          .getBool(PrefsKeyConstant.homeWidgetEnabled) ??
      true;

  /// The Settings switch.
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
      SdLogger.error(
        LogTagConstant.homeWidget,
        'Home widget toggle failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Redraws the widget from what the app currently holds.
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
      SdLogger.error(
        LogTagConstant.homeWidget,
        'Home widget refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// The GDPR wipe's share of the work (hard rule 8).
  Future<void> clear() => ref.read(homeWidgetRepositoryProvider).clear();

  /// Renders the snapshot in the user's language.
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
      // No decimal: the widget has one line for it, and 1 hPa of precision is more than a glance can use.
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
      // Only when a reading is actually drawn — attributing a blank is noise, and the widget blanks itself once the reading expires.
      attribution: snapshot.hasPressure ? l10n.weatherAttribution : '',
      trend: snapshot.trend,
    );
  }
}
