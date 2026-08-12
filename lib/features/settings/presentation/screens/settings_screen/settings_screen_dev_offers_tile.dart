part of 'settings_screen.dart';

/// Dev-only: put three fake plans on the paywall so it can be screenshotted.
///
/// Until the App Store products and the RevenueCat offering exist, the paywall
/// says "no plans available" — correct, and useless as a store screenshot.
/// Flipping this swaps in [MockPremiumOffers] at the controller, so what gets
/// captured is the real paywall with real layout, not a mockup.
///
/// Nothing is written anywhere and the branch cannot be taken in a prod
/// flavour, which is the same line `_DevPremiumTile` sits on.
class _DevOffersTile extends ConsumerWidget {
  const _DevOffersTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool mocked = ref.watch(devMockOffersProvider);

    return SettingsTile(
      icon: Icons.sell_outlined,
      iconColor: context.colorScheme.primary,
      title: l10n.settingsDevMockOffers,
      trailing: SdSwitcherV2(
        value: mocked,
        onChanged: (bool value) =>
            ref.read(devMockOffersProvider.notifier).set(value: value),
      ),
      onTap: () =>
          ref.read(devMockOffersProvider.notifier).set(value: !mocked),
    );
  }
}
