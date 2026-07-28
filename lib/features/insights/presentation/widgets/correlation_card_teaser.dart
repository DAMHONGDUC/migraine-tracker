part of 'correlation_card.dart';

/// Shown once the user HAS enough data but isn't premium — the value moment
/// the paywall is sold on. Deliberately carries no analysis output.
class _Teaser extends ConsumerWidget {
  const _Teaser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.premiumLockedCorrelation, style: AppTextStyle.bodyMedium),
        SizedBox(height: AppSpacingConstant.h12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AppButton(
            variant: AppButtonVariant.secondary,
            onPressed: () => NavigationUtils.toPaywall(context, ref),
            label: l10n.premiumUnlock,
          ),
        ),
      ],
    );
  }
}
