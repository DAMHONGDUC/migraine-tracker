import '../../l10n/gen/app_localizations.dart';

/// Formats a byte count for display. Localized because the unit sits next to the number and some locales space it differently.
final class FileSizeUtils {
  static const int _kb = 1024;
  static const int _mb = 1024 * 1024;

  static String format(AppLocalizations l10n, int bytes) {
    if (bytes < _kb) return l10n.exportSizeBytes(bytes);
    if (bytes < _mb) {
      return l10n.exportSizeKilobytes((bytes / _kb).toStringAsFixed(1));
    }

    return l10n.exportSizeMegabytes((bytes / _mb).toStringAsFixed(1));
  }
}
