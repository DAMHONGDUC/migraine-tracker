import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_location_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../domain/enums/head_location.dart';
import 'head_diagram.dart';

/// Second tap: where the pain is. The head diagram up top highlights
/// whichever region is picked from the grid below it; picking only
/// highlights — the app bar's Next confirms and advances. Everything fits
/// on one screen, no scrolling.
class LocationStep extends StatelessWidget {
  const LocationStep({required this.selected, required this.onSelected, super.key});

  final HeadLocation? selected;
  final ValueChanged<HeadLocation> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            // Full width for a bigger head; a fixed 20 breathing gap above
            // and below.
            padding: EdgeInsets.symmetric(vertical: AppSpacingConstant.h20),
            child: HeadDiagram(selected: selected),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacingConstant.w24,
            0,
            AppSpacingConstant.w24,
            AppSpacingConstant.w24,
          ),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacingConstant.h8,
            crossAxisSpacing: AppSpacingConstant.w8,
            childAspectRatio: 1,
            children: [
              for (final location in HeadLocation.values)
                _LocationTile(
                  location: location,
                  selected: selected == location,
                  onTap: () => onSelected(location),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.location,
    required this.selected,
    required this.onTap,
  });

  final HeadLocation location;
  final bool selected;
  final VoidCallback onTap;

  static const _icons = {
    HeadLocation.left: Icons.arrow_back,
    HeadLocation.right: Icons.arrow_forward,
    HeadLocation.front: Icons.north,
    HeadLocation.back: Icons.south,
    HeadLocation.whole: Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: location.label(l10n),
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(AppSpacingConstant.w4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacingConstant.r16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[location], color: color, size: AppSpacingConstant.r24),
              SizedBox(height: AppSpacingConstant.h4),
              Text(
                location.label(l10n),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.labelTiny.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
