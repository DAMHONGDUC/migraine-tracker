import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_location_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/enums/head_location.dart';

/// The five head-location tiles, three to a row. Shared by the log flow's
/// second tap ([LocationStep], under the head diagram) and the attack
/// detail's edit sheet, so correcting a location afterwards looks like
/// picking it in the first place.
///
/// Shrink-wraps and never scrolls itself: whatever holds it owns the
/// scrolling — the log step needs none, the sheet has its own.
class LocationGrid extends StatelessWidget {
  const LocationGrid({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final HeadLocation? selected;
  final ValueChanged<HeadLocation> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: SdSpacingConstant.h8,
      crossAxisSpacing: SdSpacingConstant.w8,
      childAspectRatio: 1,
      children: <Widget>[
        for (final HeadLocation location in HeadLocation.values)
          _LocationTile(
            location: location,
            selected: selected == location,
            onTap: () => onSelected(location),
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

  static const Map<HeadLocation, IconData> _icons = <HeadLocation, IconData>{
    HeadLocation.left: Icons.arrow_back,
    HeadLocation.right: Icons.arrow_forward,
    HeadLocation.front: Icons.north,
    HeadLocation.back: Icons.south,
    HeadLocation.whole: Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: location.label(l10n),
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(SdSpacingConstant.w4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                // One step above the card colour: this tile also sits on a
                // sheet, which is that colour, and would vanish into it.
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SdIconV2(
                icon: _icons[location]!,
                color: color,
                size: SdSpacingConstant.r24,
              ),
              SizedBox(height: SdSpacingConstant.h4),
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
