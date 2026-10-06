part of 'settings_screen.dart';

/// What sync is doing, at the top of Settings, as a title over one line of detail: running (with a percentage and a bar), owed, or done.
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
    final double? progress = status.progress;
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
      // Failed with records owed: offline or refused, the card cannot tell which — only that it will try again.
      SyncStatus(phase: SyncPhase.failed) when pending > 0 => (
        AppIconConstant.syncFailed,
        AppColors.error,
        l10n.syncCardPendingTitle(pending),
        l10n.syncCardFailedBody,
      ),
      // Failed with nothing owed: the pull is what broke, so "all saved" would hide it.
      SyncStatus(phase: SyncPhase.failed) => (
        AppIconConstant.syncFailed,
        AppColors.error,
        l10n.syncCardFailedTitle,
        l10n.syncCardFailedBody,
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
        // The app's one hairline, so the card reads as a framed status rather than a bare patch of surface above the rows.
        borderColor: SdOutlineV2.color(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdSpacingConstant.w12,
            vertical: SdSpacingConstant.h10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SdIconV2(icon: icon, size: AppIconSize.small, color: color),
                  SizedBox(width: SdSpacingConstant.w12),
                  // Title over detail, one line each — "Syncing" over "12/40".
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTextStyle.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          body,
                          style: AppTextStyle.bodySmall.secondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (status.isSyncing && progress != null) ...<Widget>[
                    SizedBox(width: SdSpacingConstant.w8),
                    Text(
                      NumberFormat.percentPattern(
                        l10n.localeName,
                      ).format(progress),
                      style: AppTextStyle.titleSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              if (status.isSyncing) ...<Widget>[
                SizedBox(height: SdSpacingConstant.h8),
                // Indeterminate until the first count lands: a pass that has not fetched yet knows nothing to measure.
                LinearProgressIndicator(
                  value: progress,
                  minHeight: SdSpacingConstant.h4,
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
