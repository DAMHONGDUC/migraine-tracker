import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Shorthand for the verbose `AppLocalizations.of(context)` form.
extension BuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
