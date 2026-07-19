import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/glass/liquid_glass_theme.dart';
import '../../domain/enums/history_view_mode.dart';

/// Segmented toggle for the History representations: a pill track with an
/// animated thumb that slides under the selected segment. Driven by
/// [HistoryViewMode.values], so adding a mode needs no layout maths here.
/// Calm 200ms ease — no flash.
class HistoryViewToggle extends StatelessWidget {
  const HistoryViewToggle({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final HistoryViewMode mode;
  final ValueChanged<HistoryViewMode> onChanged;

  static const _icons = {
    HistoryViewMode.list: Icons.list_alt,
    // Not calendar_month — that's the History tab's own icon in the bottom
    // nav, and one icon must not mean two things.
    HistoryViewMode.calendar: Icons.calendar_view_month,
    HistoryViewMode.chart: Icons.bar_chart,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final modes = HistoryViewMode.values;
    final segmentWidth = AppSpacingConstant.w40;
    final height = AppSpacingConstant.h34;
    final index = modes.indexOf(mode);

    final track = Container(
      width: segmentWidth * modes.length,
      height: height,
      decoration: BoxDecoration(
        // Opaque fill only when glass is off; the glass supplies the surface.
        color: kLiquidGlassEnabled ? null : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Stack(
        children: [
          // Thumb: 1/N wide, aligned to the selected segment. Fractional so
          // it fits whatever width the border leaves (no fixed-px overflow).
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            // Alignment.x spans -1 (start) … 1 (end).
            alignment: AlignmentDirectional(
              -1 + 2 * index / (modes.length - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / modes.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final m in modes)
                Expanded(
                  child: _Segment(
                    icon: _icons[m]!,
                    selected: m == mode,
                    onTap: () => onChanged(m),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (!kLiquidGlassEnabled) return track;
    // A frosted pill: it refracts the (glass) app bar and the content behind
    // it. The thumb + icons paint crisply on top (glassContainsChild: false).
    return LiquidGlass.withOwnLayer(
      settings: kChromeGlass,
      shape: LiquidRoundedSuperellipse(borderRadius: height / 2),
      clipBehavior: Clip.antiAlias,
      child: track,
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Icon(
          icon,
          size: AppSpacingConstant.r20,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
