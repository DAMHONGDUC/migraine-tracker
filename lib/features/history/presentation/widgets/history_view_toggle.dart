import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
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
    HistoryViewMode.list: AppIconConstant.listView,
    // Not calendar_month — that's the History tab's own icon in the bottom nav, and one icon must not mean two things.
    HistoryViewMode.calendar: AppIconConstant.calendarView,
    HistoryViewMode.chart: AppIconConstant.barChart,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final modes = HistoryViewMode.values;
    final segmentWidth = SdSpacingConstant.w54;
    final height = SdSpacingConstant.h42;
    final index = modes.indexOf(mode);

    // Styled like the bottom nav pill: borderless glass surface, thumb floats inside the track with its own inset.
    final track = Container(
      width: segmentWidth * modes.length,
      height: height,
      decoration: BoxDecoration(
        // Opaque fill only when glass is off; the glass supplies the surface.
        color: SdGlassV2.isSupported ? null : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(height / 2),
        // A hairline edge so the track reads as a control against the app
        // bar behind it — frosted glass alone left its bounds guessable.
        border: Border.all(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Stack(
        children: [
          // Thumb: 1/N wide, aligned to the selected segment.
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SdSpacingConstant.w4,
                  vertical: SdSpacingConstant.h4,
                ),
                // Solid, not a 22% wash. Over a frosted track on a dark
                // background that tint was almost invisible, and "which view
                // am I in" is the only thing this control says.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(
                      SdSpacingConstant.r999,
                    ),
                  ),
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
                    label: switch (m) {
                      HistoryViewMode.list => context.l10n.a11yViewList,
                      HistoryViewMode.calendar => context.l10n.a11yViewCalendar,
                      HistoryViewMode.chart => context.l10n.a11yViewChart,
                    },
                    selected: m == mode,
                    onTap: () => onChanged(m),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (!SdGlassV2.isSupported) return track;
    // A frosted pill: refracts the (glass) app bar and content behind it, thumb + icons paint crisply on top (glassContainsChild: false).
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
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    // Icon-only segment — VoiceOver needs the name + selected state.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: SdIconV2(
            // `row`, not `tile`: the segment is icon-only, but the thumb it
            // sits in is 34 tall (h42 less its h4 inset either side), and a
            // 28 glyph leaves it 3pt of breathing room.
            icon: icon,
            size: AppIconSize.row,
            // Dark on the filled thumb, light off it — the pair inverts, so
            // the selected one is legible rather than merely tinted.
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
