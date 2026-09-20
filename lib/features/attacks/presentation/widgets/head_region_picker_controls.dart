part of 'head_region_picker.dart';

/// The head's camera controls, floating over the head itself.
///
/// **Overlaid rather than stacked above it** (owner's rule, 2026-09-19): as a
/// row of its own it took 44pt off the one screen this step is allowed, for
/// four targets and a line of hint text. Over the head it costs nothing, and
/// what it covers is the air above the crown.
class _HeadZoomControls extends StatelessWidget {
  const _HeadZoomControls({
    required this.zoom,
    required this.rotationSpeed,
    required this.onZoom,
    required this.onReduceRotationSpeed,
    required this.onReset,
  });

  final double zoom;
  final HeadRotationSpeed rotationSpeed;
  final ValueChanged<double> onZoom;
  final VoidCallback onReduceRotationSpeed;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV2.horizontal),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              l10n.logHeadGestureHint,
              maxLines: 2,
              style: AppTextStyle.labelTiny.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Tinted while the turn is slowed, because the setting is otherwise
          // felt rather than seen: the button's own glyph never changes, and
          // a control whose state only shows up in a tooltip is a control
          // nobody can check.
          _HeadZoomButton(
            label: l10n.logHeadRotationSpeed(rotationSpeed.percent),
            icon: Symbols.speed_rounded,
            tint: rotationSpeed == HeadRotationSpeed.full
                ? null
                : AppColors.primary,
            onPressed: onReduceRotationSpeed,
          ),
          _HeadZoomButton(
            label: l10n.logHeadZoomOut,
            icon: Symbols.remove_rounded,
            onPressed: zoom <= HeadViewportUtils.minZoom
                ? null
                : () => onZoom(zoom - HeadViewportUtils.zoomStep),
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.logHeadZoomLevel((zoom * 100).round()),
              style: AppTextStyle.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _HeadZoomButton(
            label: l10n.logHeadZoomIn,
            icon: Symbols.add_rounded,
            onPressed: zoom >= HeadViewportUtils.maxZoom
                ? null
                : () => onZoom(zoom + HeadViewportUtils.zoomStep),
          ),
          _HeadZoomButton(
            label: l10n.logHeadResetView,
            icon: Symbols.restart_alt_rounded,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

class _HeadZoomButton extends StatelessWidget {
  const _HeadZoomButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tint,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Overrides the resting colour, for a button that is also a readout.
  final Color? tint;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    constraints: BoxConstraints(
      minWidth: SdSpacingConstant.r44,
      minHeight: SdSpacingConstant.r44,
    ),
    icon: SdIconV2(
      icon: icon,
      size: SdSpacingConstant.r20,
      color: onPressed == null
          ? AppColors.chartGrid
          : tint ?? AppColors.textSecondary,
    ),
  );
}
