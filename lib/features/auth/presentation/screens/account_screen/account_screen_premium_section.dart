part of 'account_screen.dart';

/// Entitlement state, read from [hasPremiumProvider] — the one source every
/// gate uses, never a flag stored on the account document. The row is a
/// summary; the detail (and the purchase) lives on [PremiumScreen].
class _PremiumSection extends ConsumerWidget {
  const _PremiumSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool premium = ref.watch(hasPremiumProvider);

    return ListTile(
      leading: SdIconV2(
        icon: premium ? Icons.workspace_premium : Icons.lock_outline,
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
      trailing: const SdIconV2(icon: Icons.chevron_right),
      onTap: () => context.pushNamed(AppRoutes.premium.name),
    );
  }
}
