import '../../l10n/gen/app_localizations.dart';

/// "7h 20m" for a span of sleep. Localized because the units sit against the
/// numbers and locales space them differently.
extension DurationLabel on Duration {
  /// Sign is dropped — a caller showing a difference says which way round it
  /// goes in its own sentence, not with a minus in the middle of a number.
  String label(AppLocalizations l10n) {
    final Duration span = abs();

    return l10n.commonDurationHoursMinutes(
      span.inHours,
      span.inMinutes.remainder(60),
    );
  }
}
