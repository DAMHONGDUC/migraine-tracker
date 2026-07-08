import '../../features/attacks/domain/enums/head_location.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shared user-facing labels for [HeadLocation]; used by the log flow and
/// history so features don't import each other's presentation layer.
extension HeadLocationLabel on HeadLocation {
  String label(AppLocalizations l10n) => switch (this) {
    HeadLocation.left => l10n.locationLeft,
    HeadLocation.right => l10n.locationRight,
    HeadLocation.front => l10n.locationFront,
    HeadLocation.back => l10n.locationBack,
    HeadLocation.whole => l10n.locationWhole,
  };
}
