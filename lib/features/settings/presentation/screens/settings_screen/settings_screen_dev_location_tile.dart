part of 'settings_screen.dart';

/// Dev-only: read the weather at a fixed city instead of the device position.
///
/// **This exists for the Simulator**, which reports no location at all — so
/// every weather read stopped at "no location" before reaching the backend,
/// and that is indistinguishable on screen from a backend that is broken
/// (hard rule 4 gives all three failures one message). Pinning a city
/// separates the two questions: still nothing, and the problem is the backend.
///
/// Compiled out of a prod flavour with the rest of the section, and
/// `DevLocationController` refuses to read the preference there as well.
class _DevLocationTile extends ConsumerWidget {
  const _DevLocationTile();

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final DevLocation current = ref.read(devLocationProvider);
    final DevLocation? picked = await showSdFilterSheetV2<DevLocation>(
      context,
      title: l10n.settingsDevLocationSheetTitle,
      options: DevLocation.values,
      selected: current,
      labelBuilder: (DevLocation location) => location.label(l10n),
    );

    if (picked == null || picked == current) return;

    await ref.read(devLocationProvider.notifier).set(picked);

    // The report is cached for an hour and survives a rebuild by design, so
    // without this the card would keep drawing the old city until the TTL ran
    // out — which reads as the picker having done nothing.
    ref
      ..invalidate(weatherReportProvider)
      ..invalidate(pressureForecastProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return SettingsTile(
      icon: AppIconConstant.locationUnknown,
      iconColor: AppColors.secondary,
      title: l10n.settingsDevLocation,
      value: ref.watch(devLocationProvider).label(l10n),
      onTap: () => _pick(context, ref),
    );
  }
}

extension _DevLocationX on DevLocation {
  String label(AppLocalizations l10n) => switch (this) {
    DevLocation.off => l10n.settingsDevLocationOff,
    DevLocation.hanoi => l10n.settingsDevLocationHanoi,
    DevLocation.tokyo => l10n.settingsDevLocationTokyo,
    DevLocation.london => l10n.settingsDevLocationLondon,
    DevLocation.sanFrancisco => l10n.settingsDevLocationSanFrancisco,
  };
}
