import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final segmentWidth = 44.w;
    final height = 34.h;

    return Container(
      width: segmentWidth * 2,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: mode == HistoryViewMode.list
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: Container(
              width: segmentWidth,
              height: height,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
          Row(
            children: [
              _Segment(
                icon: Icons.list_alt,
                selected: mode == HistoryViewMode.list,
                width: segmentWidth,
                onTap: () => onChanged(HistoryViewMode.list),
              ),
              _Segment(
                icon: Icons.bar_chart,
                selected: mode == HistoryViewMode.chart,
                width: segmentWidth,
                onTap: () => onChanged(HistoryViewMode.chart),
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
    required this.width,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Icon(
          icon,
          size: 20.r,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
