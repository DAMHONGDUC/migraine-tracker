part of 'settings_screen.dart';

/// Dev-only: force premium on or off without going near the store.

class _DevPremiumTile extends ConsumerWidget {
  const _DevPremiumTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    // The real answer while nothing is forced, so the row starts where the app actually is.
    final bool premium = ref.watch(hasPremiumProvider);

    return SettingsTile(
      icon: AppIconConstant.premium,
      iconColor: context.colorScheme.primary,
      title: l10n.settingsDevPremium,
      trailing: SdSwitcherV2(
        value: premium,
        onChanged: (bool value) =>
            ref.read(devPremiumOverrideProvider.notifier).set(value),
      ),
      onTap: () => ref.read(devPremiumOverrideProvider.notifier).set(!premium),
    );
  }
}
