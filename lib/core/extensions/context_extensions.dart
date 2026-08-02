import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Shorthand for the verbose `AppLocalizations.of(context)` form.
///
/// Theme accessors (`context.theme`, `context.colorScheme`) live in
/// `system_design_v2`: the design system owns those, this app owns its
/// strings.
extension BuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
