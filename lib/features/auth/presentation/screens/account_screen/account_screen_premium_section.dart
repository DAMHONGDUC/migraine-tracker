part of 'account_screen.dart';

/// Entitlement state, read from [hasPremiumProvider] — the one source every gate uses, never a flag stored on the account document.
class _PremiumSection extends ConsumerWidget {
  const _PremiumSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool premium = ref.watch(hasPremiumProvider);

    return ListTile(
      leading: SdIconV2(
        icon: premium ? AppIconConstant.premium : AppIconConstant.locked,
        color: premium ? context.colorScheme.primary : null,
      ),
      title: Text(
        premium ? l10n.accountPremiumActive : l10n.accountPremiumFree,
        style: AppTextStyle.bodyLarge,
      ),
      subtitle: Text(
        premium ? l10n.accountPremiumActiveBody : l10n.accountPremiumFreeBody,
        style: AppTextStyle.bodyMedium.secondary,
      ),
      trailing: SdIconV2(
        icon: AppIconConstant.disclosure,
        size: AppIconSize.small,
      ),
      onTap: () => context.pushNamed(AppRoutes.premium.name),
    );
  }
}
