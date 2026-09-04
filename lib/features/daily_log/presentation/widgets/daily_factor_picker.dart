import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/daily_factor_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/enums/daily_factor.dart';

/// The day's factors, two to a row — the same tile the log flow's option grids use, so the two screens read as one app.
class DailyFactorPicker extends StatelessWidget {
  const DailyFactorPicker({
    required this.selected,
    required this.onToggled,
    super.key,
  });

  final Set<DailyFactor> selected;
  final ValueChanged<DailyFactor> onToggled;

  /// Two to a row, as everywhere else in the app that offers word-length options.
  static const int optionsPerRow = 2;

  static const Map<DailyFactor, IconData> _icons = <DailyFactor, IconData>{
    DailyFactor.skippedMeal: AppIconConstant.factorSkippedMeal,
    DailyFactor.dehydration: AppIconConstant.factorDehydration,
    DailyFactor.caffeine: AppIconConstant.factorCaffeine,
    DailyFactor.alcohol: AppIconConstant.factorAlcohol,
    DailyFactor.screenTime: AppIconConstant.factorScreenTime,
    DailyFactor.intenseExercise: AppIconConstant.factorIntenseExercise,
    DailyFactor.travel: AppIconConstant.factorTravel,
    DailyFactor.strongSmell: AppIconConstant.factorStrongSmell,
  };

  @override
  Widget build(BuildContext context) {
    final List<DailyFactor> factors = DailyFactor.values;

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      // Whatever holds this owns the scrolling — the screen is one list.
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: optionsPerRow,
        mainAxisSpacing: SdSpacingConstant.h8,
        crossAxisSpacing: SdSpacingConstant.w8,
        // A fixed row height, not an aspect ratio: the tile is one line beside an icon, so its height has nothing to do with the screen's width.
        mainAxisExtent: SdSpacingConstant.h64,
      ),
      itemCount: factors.length,
      itemBuilder: (BuildContext context, int index) => _FactorTile(
        factor: factors[index],
        icon: _icons[factors[index]]!,
        selected: selected.contains(factors[index]),
        onTap: () => onToggled(factors[index]),
      ),
    );
  }
}

class _FactorTile extends StatelessWidget {
  const _FactorTile({
    required this.factor,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final DailyFactor factor;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: factor.label(l10n),
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              SdIconV2(icon: icon, color: color, size: AppIconSize.medium),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Text(
                  factor.label(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.titleSmall.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
