import '../../features/insights/domain/enums/map_factor.dart';
import '../../l10n/gen/app_localizations.dart';
import 'daily_factor_label.dart';

/// Shared user-facing labels for [MapFactor]. The eight that mirror a check-in tick borrow its word, so one factor is never named two ways.
extension MapFactorLabel on MapFactor {
  String label(AppLocalizations l10n) =>
      daily?.label(l10n) ??
      switch (this) {
        MapFactor.poorSleep => l10n.factorPoorSleep,
        MapFactor.highStress => l10n.factorHighStress,
        MapFactor.highHumidity => l10n.factorHighHumidity,
        MapFactor.tempSwing => l10n.factorTempSwing,
        _ => '',
      };
}
