part of 'head_region_picker.dart';

/// The head's camera controls, sharing the top row with the Front/Back tabs.
///
/// **Up beside the tabs, not over the head** (owner's rule, 2026-09-21). They
/// floated over the head from 2026-09-19, which cost nothing while the head
/// was framed with air above the crown. Once it opens filling its box
/// (`HeadViewportUtils.fitZoom`) that air is gone and the same overlay sits on
/// the crown — a region the user has to be able to tap. The tabs had width
/// they were not using, so the controls took it.
///
/// **It carries no hint line any more** (owner's call, 2026-09-21). "Drag to
/// rotate · Pinch to zoom" was the widest thing in the row and there is no
/// room for it beside the tabs; a line of its own would cost the head height,
/// which is what moving up here was for.
class _HeadZoomControls extends StatelessWidget {
  const _HeadZoomControls({
    required this.zoom,
    required this.rotationSpeed,
    required this.onZoom,
    required this.onReduceRotationSpeed,
    required this.onReset,
  });

  /// The row's height, which the picker needs before it can size the head.
  ///
  /// The buttons' own tap target, which is the tallest thing in here — pinned
  /// rather than measured, because an intrinsic height is only known once the
  /// row has been laid out and the head's box is decided before that.
  static double get height => SdSpacingConstant.r44;

  final double zoom;
  final HeadRotationSpeed rotationSpeed;
  final ValueChanged<double> onZoom;
  final VoidCallback onReduceRotationSpeed;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SizedBox(
      height: height,
      // Only as wide as its five targets: the rest of the row is the tabs'.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Keep the speed readable without opening its tooltip.
          _HeadZoomButton(
            label: l10n.logHeadRotationSpeed(rotationSpeed.percent),
            icon: Symbols.speed_rounded,
            readout: l10n.logHeadRotationSpeedValue(rotationSpeed.percent),
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
    this.readout,
  });

  final String label;
  final String? readout;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Overrides the resting colour, for a button that is also a readout.
  final Color? tint;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    // The 44pt target comes from the constraints, not from padding round a
    // 20pt glyph: padded, the speed button's icon-over-readout column comes
    // out TALLER than the row it now shares with the tabs, and wider than the
    // width the tabs can spare it.
    padding: EdgeInsets.zero,
    constraints: BoxConstraints(
      minWidth: SdSpacingConstant.r44,
      minHeight: SdSpacingConstant.r44,
    ),
    icon: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SdIconV2(
          icon: icon,
          size: readout == null ? SdSpacingConstant.r20 : SdSpacingConstant.r16,
          color: onPressed == null
              ? AppColors.chartGrid
              : tint ?? AppColors.textSecondary,
        ),
        if (readout != null)
          Text(
            readout!,
            style: AppTextStyle.labelTiny.copyWith(
              color: tint ?? AppColors.textSecondary,
            ),
          ),
      ],
    ),
  );
}
