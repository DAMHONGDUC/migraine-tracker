import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Shorthand accessors used across every screen; prefer these over the
/// verbose `AppLocalizations.of(context)` / `Theme.of(context)` forms.
extension BuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
}
