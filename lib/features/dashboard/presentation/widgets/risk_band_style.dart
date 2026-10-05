import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../insights/domain/entities/risk_score.dart';

/// A risk band's colour and word, in one place so the card's mini bars, the screen's columns and every number can never disagree.
final class RiskBandStyle {
  static Color color(RiskBand band) => switch (band) {
    RiskBand.low => AppColors.primary,
    RiskBand.moderate => AppColors.intensity(5),
    RiskBand.high => AppColors.intensity(9),
  };

  static String label(RiskBand band, AppLocalizations l10n) => switch (band) {
    RiskBand.low => l10n.riskBandLow,
    RiskBand.moderate => l10n.riskBandModerate,
    RiskBand.high => l10n.riskBandHigh,
  };
}
