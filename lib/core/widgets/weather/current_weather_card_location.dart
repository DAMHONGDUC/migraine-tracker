part of 'current_weather_card.dart';

/// The weather card with no position to draw: what the reading needs, and the button that grants it.
class _LocationPrompt extends ConsumerWidget {
  const _LocationPrompt();

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    SdLogger.action(LogTagConstant.location, 'Enable location', 'weather card');

    try {
      final bool granted = await ref
          .read(appPermissionProvider)
          .ensure(context, AppPermissionType.location);

      SdLogger.info(LogTagConstant.location, 'Location answered', granted);
      // Whichever way it went: a denial that has become permanent changes what the next tap does, and only re-reading the status can tell.
      ref.invalidate(locationPermissionProvider);

      // And the reading itself, or the grant buys nothing.
      if (granted) {
        ref.invalidate(weatherReportProvider);
        ref.invalidate(placeNameProvider);
      }
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.location,
        'Requesting location from the weather card failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdCardV2(
      gradient: WeatherCard.gradient(context),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w16,
          vertical: SdSpacingConstant.h12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SdIconV2(
                  icon: AppIconConstant.locationOff,
                  size: AppIconSize.row,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: Text(
                    context.l10n.weatherLocationOffBody,
                    style: AppTextStyle.bodyMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SdButtonV2(
                variant: SdButtonVariantV2.primary,
                size: SdButtonSizeV2.small,
                compact: true,
                onPressed: () => _request(context, ref),
                label: context.l10n.weatherLocationOffAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
