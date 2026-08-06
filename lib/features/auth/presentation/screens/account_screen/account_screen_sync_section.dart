part of 'account_screen.dart';

/// The one place a sync is visible in full (hard rule 12): a strip at the top
/// of the screen while a pass is in flight, and nothing at all when idle.
class _SyncProgress extends ConsumerWidget {
  const _SyncProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isSyncingProvider)) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdSpacingConstant.w16,
        SdSpacingConstant.h8,
        SdSpacingConstant.w16,
        SdSpacingConstant.h8,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: SdSpacingConstant.r20,
            height: SdSpacingConstant.r20,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Text(
              context.l10n.accountSyncing,
              style: AppTextStyle.bodyMedium.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sync runs on its own; this is only here for a deliberate retry, which is
/// why the note under it says so rather than making the button look required.
class _SyncSection extends ConsumerWidget {
  const _SyncSection();

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;

    await ref.read(syncControllerProvider.notifier).sync();

    // The controller never throws — a deliberate tap still deserves an answer
    // when nothing happened, so the outcome is read back off the state.
    if (!context.mounted) return;
    if (ref.read(syncControllerProvider).phase == SyncPhase.failed) {
      SdSnackBarUtilsV2.error(context, l10n.accountSyncFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool isSyncing = ref.watch(isSyncingProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.secondary,
            onPressed: isSyncing ? null : () => _syncNow(context, ref),
            label: l10n.accountSyncNow,
            icon: Icons.sync,
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Text(l10n.accountSyncNote, style: AppTextStyle.bodySmall.secondary),
        ],
      ),
    );
  }
}
