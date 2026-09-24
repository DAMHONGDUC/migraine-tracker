part of 'settings_screen.dart';

/// What sync is doing, at the top of Settings: running (with a bar), owed, or done.
///
/// Sign-out refuses while anything is owed, so this is where a user sees that
/// coming (owner's rule, 2026-09-24). No button — sync is automatic
/// (`lib/features/sync/CLAUDE.md`).
class _SyncCard extends ConsumerWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final SyncStatus status = ref.watch(syncControllerProvider);
    final int? pending = status.pending;
    final (
      IconData icon,
      Color color,
      String title,
      String body,
    ) = switch (status) {
      SyncStatus(isSyncing: true, total: > 0) => (
        AppIconConstant.syncing,
        AppColors.primary,
        l10n.syncCardSyncingTitle,
        l10n.syncCardProgress(status.done, status.total),
      ),
      SyncStatus(isSyncing: true) => (
        AppIconConstant.syncing,
        AppColors.primary,
        l10n.syncCardSyncingTitle,
        l10n.syncCardChecking,
      ),
      _ when pending == null => (
        AppIconConstant.syncing,
        AppColors.textSecondary,
        l10n.syncCardCheckingTitle,
        l10n.syncCardChecking,
      ),
      _ when pending > 0 => (
        AppIconConstant.syncPending,
        AppColors.warning,
        l10n.syncCardPendingTitle(pending),
        l10n.syncCardPendingBody,
      ),
      _ => (
        AppIconConstant.synced,
        AppColors.secondary,
        l10n.syncCardSavedTitle,
        l10n.syncCardSavedBody,
      ),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV2.horizontal,
        SdContentPaddingV2.topGap,
        SdContentPaddingV2.horizontal,
        0,
      ),
      child: SdCardV2(
        child: Padding(
          padding: EdgeInsets.all(SdSpacingConstant.w16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SdIconV2(icon: icon, size: AppIconSize.medium, color: color),
                  SizedBox(width: SdSpacingConstant.w12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title, style: AppTextStyle.titleSmall),
                        SizedBox(height: SdSpacingConstant.h2),
                        Text(body, style: AppTextStyle.bodySmall.secondary),
                      ],
                    ),
                  ),
                ],
              ),
              if (status.isSyncing) ...<Widget>[
                SizedBox(height: SdSpacingConstant.h12),
                // Indeterminate until the first count lands: a pass that has not fetched yet knows nothing to measure.
                LinearProgressIndicator(
                  value: status.progress,
                  minHeight: SdSpacingConstant.h6,
                  borderRadius: BorderRadius.circular(SdSpacingConstant.r3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
