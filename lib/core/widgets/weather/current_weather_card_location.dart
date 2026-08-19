part of 'current_weather_card.dart';

/// The weather card with no position to draw: what the reading needs, and the
/// button that grants it.
///
/// **It keeps the card's shape** — the same gradient, the same two lines — so
/// the dashboard neither gains nor loses a card as the permission changes;
/// only what fills it does.
///
/// **This is the second place the app asks for location, and the first
/// outside onboarding** (owner's call). The onboarding step is still where
/// the ask is explained, but a "Not now" there used to be final: nothing in
/// the app asked again, and the card the permission feeds said only that the
/// weather was unavailable. Asking here is asking on the surface the answer
/// changes.
///
/// **The prompt is [AppPermission.ensure], not the geolocator's own
/// request.** Once iOS has been told no it will not show its dialog again, so
/// the ask has to be able to fall through to `PermissionSettingsSheet` and
/// the Settings app — a button that silently did nothing is exactly what a
/// second ask must not be.
class _LocationPrompt extends ConsumerWidget {
  const _LocationPrompt();

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    SdLogger.action(LogTagConstant.location, 'Enable location', 'weather card');

    try {
      final bool granted = await ref
          .read(appPermissionProvider)
          .ensure(context, AppPermissionType.location);

      SdLogger.info(LogTagConstant.location, 'Location answered', granted);
      // Whichever way it went: a denial that has become permanent changes
      // what the next tap does, and only re-reading the status can tell.
      ref.invalidate(locationPermissionProvider);
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
                  icon: Icons.location_off_outlined,
                  size: SdSpacingConstant.r20,
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
