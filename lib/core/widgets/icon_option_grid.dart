import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../theme/app_colors.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_text_style.dart';

/// One option in an [IconOptionGrid]: a glyph, a word, and whether it is on.
@immutable
class IconOption {
  const IconOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onToggled,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onToggled;
}

/// A multi-select grid of glyph-and-word tiles, two to a row.
///
/// It is the one owner of that tile: the check-in's factors, an attack's
/// symptoms and an attack's triggers all draw it, and three copies of one
/// decoration is how three screens come to look like three apps.
class IconOptionGrid extends StatelessWidget {
  const IconOptionGrid({required this.options, super.key});

  final List<IconOption> options;

  /// Two to a row, as everywhere else in the app that offers word-length options.
  static const int optionsPerRow = 2;

  /// One line beside a glyph — a fixed row height, never an aspect ratio, so the tile's height has nothing to do with the screen's width.
  static double get tileHeight => SdSpacingConstant.h64;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      // Whatever holds this owns the scrolling — the screen is one list.
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: optionsPerRow,
        mainAxisSpacing: SdSpacingConstant.h8,
        crossAxisSpacing: SdSpacingConstant.w8,
        mainAxisExtent: tileHeight,
      ),
      itemCount: options.length,
      itemBuilder: (BuildContext context, int index) =>
          _OptionTile(option: options[index]),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option});

  final IconOption option;

  @override
  Widget build(BuildContext context) {
    final bool selected = option.selected;
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: option.onToggled,
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
              SdIconV2(
                icon: option.icon,
                color: color,
                size: AppIconSize.medium,
              ),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Text(
                  option.label,
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
