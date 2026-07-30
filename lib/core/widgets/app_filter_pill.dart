import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';
import 'app_icon.dart';

/// The pill that opens a filter: a leading filter glyph, the value currently
/// filtered to, a chevron saying there is more behind it.
///
/// Look only — what the tap opens belongs to the caller. `AppFilterChip` puts
/// a single-choice sheet behind it (History's period, the medications tab's
/// three axes); the export screen puts its own date-range sheet there. The
/// pill itself is shared so those never drift into two different pills.
class AppFilterPill extends StatelessWidget {
  const AppFilterPill({required this.label, required this.onTap, super.key});

  /// The pill's own height — what History measures its scroll hand-off against
  /// (`_FilterRow.scrolledPastExtent`), since the pill leads the list there.
  static double get pillHeight => AppSpacingConstant.h34;

  /// Text on the closed pill — the finished, localized value.
  final String label;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppSpacingConstant.r20),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacingConstant.r20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacingConstant.w14,
            vertical: AppSpacingConstant.h8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(
                Icons.filter_list,
                size: AppSpacingConstant.r16,
                color: scheme.primary,
              ),
              SizedBox(width: AppSpacingConstant.w6),
              Text(label, style: AppTextStyle.labelLarge),
              SizedBox(width: AppSpacingConstant.w2),
              AppIcon(
                Icons.expand_more,
                size: AppSpacingConstant.r18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
