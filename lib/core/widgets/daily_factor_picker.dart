import 'package:flutter/material.dart';

import '../../features/daily_log/domain/enums/daily_factor.dart';
import '../../l10n/gen/app_localizations.dart';
import '../extensions/context_extensions.dart';
import '../extensions/daily_factor_label.dart';
import '../theme/app_icon_constant.dart';
import 'icon_option_grid.dart';

/// The day's factors, two to a row — [IconOptionGrid] draws the tiles, so the check-in and the log flow read as one app.
///
/// It lives in `core/widgets/` because two features draw it: the check-in asks
/// for the day's factors, and an attack's details sheet offers the same
/// vocabulary as its triggers — which is what makes a trigger gradeable
/// (`lib/features/daily_log/CLAUDE.md`).
class DailyFactorPicker extends StatelessWidget {
  const DailyFactorPicker({
    required this.selected,
    required this.onToggled,
    super.key,
  });

  final Set<DailyFactor> selected;
  final ValueChanged<DailyFactor> onToggled;

  /// One glyph per factor, and every factor must have one — a tile with no glyph is half a tile.
  static const Map<DailyFactor, IconData> icons = <DailyFactor, IconData>{
    DailyFactor.skippedMeal: AppIconConstant.factorSkippedMeal,
    DailyFactor.dehydration: AppIconConstant.factorDehydration,
    DailyFactor.caffeine: AppIconConstant.factorCaffeine,
    DailyFactor.alcohol: AppIconConstant.factorAlcohol,
    DailyFactor.screenTime: AppIconConstant.factorScreenTime,
    DailyFactor.intenseExercise: AppIconConstant.factorIntenseExercise,
    DailyFactor.travel: AppIconConstant.factorTravel,
    DailyFactor.strongSmell: AppIconConstant.factorStrongSmell,
    DailyFactor.brightLight: AppIconConstant.factorBrightLight,
    DailyFactor.loudNoise: AppIconConstant.factorLoudNoise,
    DailyFactor.neckTension: AppIconConstant.factorNeckTension,
    DailyFactor.missedMedication: AppIconConstant.factorMissedMedication,
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return IconOptionGrid(
      options: <IconOption>[
        for (final DailyFactor factor in DailyFactor.values)
          IconOption(
            label: factor.label(l10n),
            icon: icons[factor]!,
            selected: selected.contains(factor),
            onToggled: () => onToggled(factor),
          ),
      ],
    );
  }
}
