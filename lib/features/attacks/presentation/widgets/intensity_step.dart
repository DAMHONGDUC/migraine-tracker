import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/intensity_severity_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// First tap: pain intensity 1–10.
///
/// **Ten tiles in a 5×2 grid, each carrying its band's bar, with the four
/// bands named under it** (2026-09-30 redesign). The discs this replaced stood
/// in four rows of three, three, two and two — a staircase whose rows said
/// nothing — and left the colour as the only way to tell mild from extreme.
/// The legend is what makes the colour a second signal instead of the only one
/// (hard rule 3). **The tap still commits**: this step is the one tap of the
/// three hard rule 5 protects that advances on the pick.
class IntensityStep extends StatelessWidget {
  const IntensityStep({required this.onSelected, super.key});

  final ValueChanged<int> onSelected;

  /// Tiles per row: ten in two rows of five, so both rows are the same length.
  static const int _perRow = 5;

  /// Each band's first and last value, worst last — the legend's own order.
  static const List<(int, int)> _bands = <(int, int)>[
    (1, 3),
    (4, 6),
    (7, 8),
    (9, 10),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      // Scrollable so the grid never overflows a short screen or a large text size.
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV2.horizontal,
          vertical: SdSpacingConstant.h24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int row = 0; row < 10 ~/ _perRow; row++) ...<Widget>[
              if (row > 0) SizedBox(height: SdSpacingConstant.h12),
              Row(
                children: <Widget>[
                  for (int col = 0; col < _perRow; col++) ...<Widget>[
                    if (col > 0) SizedBox(width: SdSpacingConstant.w12),
                    Expanded(
                      child: _IntensityTile(
                        value: row * _perRow + col + 1,
                        onTap: () => onSelected(row * _perRow + col + 1),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            SizedBox(height: SdSpacingConstant.h24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: SdSpacingConstant.w16,
              runSpacing: SdSpacingConstant.h8,
              children: <Widget>[
                for (final (int low, int high) in _bands)
                  _LegendEntry(
                    color: AppColors.intensity(low),
                    label: '${low.severityTitle(l10n)} $low–$high',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One value: the number over its band's bar, on a tile the whole width of its column.
class _IntensityTile extends StatelessWidget {
  const _IntensityTile({required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  /// A tile is tall enough for the number and its bar, and past the 44 touch minimum either way.
  static double get height => SdSpacingConstant.h68;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Color color = AppColors.intensity(value);

    // VoiceOver hears the number and the band; the bare "$value" is hidden.
    return Semantics(
      button: true,
      label: l10n.a11yIntensityButton(value, value.severityLabel(l10n)),
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('$value', style: AppTextStyle.headlineSmall),
              SizedBox(height: SdSpacingConstant.h6),
              Container(
                width: SdSpacingConstant.w20,
                height: SdSpacingConstant.h4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(SdSpacingConstant.r4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A band's colour dot and its name with the range it covers.
class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SdColorDotV2(color: color),
        SizedBox(width: SdSpacingConstant.w6),
        Text(label, style: AppTextStyle.bodySmall.secondary),
      ],
    );
  }
}
