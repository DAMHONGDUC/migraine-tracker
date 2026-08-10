import '../../l10n/gen/app_localizations.dart';
import '../utils/date_time_utils.dart';

/// Renders a [Duration] as the app's compact "3h 20m".
///
/// An extension rather than a widget helper because three places need the
/// same string — the detail row, the picker's tiles and the doctor report —
/// and a private formatter in one of them is how the three end up rounding
/// differently.
extension DurationLabel on Duration {
  String label(AppLocalizations l10n) {
    final (int hours, int minutes) = DateTimeUtils.splitHm(this);

    if (hours > 0 && minutes > 0) return l10n.attackDurationHm(hours, minutes);
    if (hours > 0) return l10n.attackDurationH(hours);
    return l10n.attackDurationM(minutes);
  }
}
