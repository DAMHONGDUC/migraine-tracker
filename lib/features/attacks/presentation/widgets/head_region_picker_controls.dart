part of 'head_region_picker.dart';

class _HeadZoomControls extends StatelessWidget {
  const _HeadZoomControls({
    required this.zoom,
    required this.onZoom,
    required this.onReset,
  });

  final double zoom;
  final ValueChanged<double> onZoom;
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
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

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
      color: onPressed == null ? AppColors.chartGrid : AppColors.textSecondary,
    ),
  );
}
