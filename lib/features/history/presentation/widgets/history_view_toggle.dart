import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/history_view_mode.dart';

/// Custom segmented toggle for list ↔ chart: a pill track with an animated
/// thumb that slides under the selected segment. Calm 200ms ease — no flash.
class HistoryViewToggle extends StatelessWidget {
  const HistoryViewToggle({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final HistoryViewMode mode;
  final ValueChanged<HistoryViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final segmentWidth = AppSpacingConstant.w44;
    final height = AppSpacingConstant.h34;

    return Container(
      width: segmentWidth * 2,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Stack(
        children: [
          // Thumb: half-width, slides under the selected segment. Fractional
          // so it fits whatever width the border leaves (no fixed-px overflow).
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: mode == HistoryViewMode.list
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 0.5,
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
              Expanded(
                child: _Segment(
                  icon: Icons.list_alt,
                  selected: mode == HistoryViewMode.list,
                  onTap: () => onChanged(HistoryViewMode.list),
                ),
              ),
              Expanded(
                child: _Segment(
                  icon: Icons.bar_chart,
                  selected: mode == HistoryViewMode.chart,
                  onTap: () => onChanged(HistoryViewMode.chart),
                ),
              ),
            ],
          ),
        ],
      ),
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
