import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/sync_status.dart';
import '../../../providers.dart';

/// Where sync is visible in full: how far the pass in flight has got, when
/// the last one finished, and the one manual control (hard rule 12).
///
/// Pushed from the Settings row, which shows only the short version. The
/// router turns it away while signed out — there is nowhere to sync to.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final SyncStatus status = ref.watch(syncControllerProvider);

    return SdScaffoldV2(
      title: Text(l10n.syncScreenTitle, style: AppTextStyle.titleLarge),
      body: SdActionViewV2(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.syncScreenBody, style: AppTextStyle.bodyMedium.secondary),
            SizedBox(height: SdContentPaddingV2.sectionGap),
            _SyncState(status: status),
          ],
        ),
        actions: const <Widget>[_SyncNowButton()],
      ),
    );
  }
}

/// The progress bar while a pass runs, the last-synced time when it does not.
class _SyncState extends StatelessWidget {
  const _SyncState({required this.status});

  final SyncStatus status;

  String _lastSynced(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime? at = status.lastSyncedAt;

    if (status.phase == SyncPhase.failed) return l10n.settingsSyncStatusFailed;
    if (at == null) return l10n.settingsSyncStatusNever;
    return DateFormat.yMMMd(l10n.localeName).add_Hm().format(at);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    if (!status.isSyncing) {
      return SdCardV2(
        child: Padding(
          padding: SdContentPaddingV2.button,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(l10n.syncScreenLastSynced, style: AppTextStyle.bodyLarge),
              Flexible(
                child: Text(
                  _lastSynced(context),
                  style: AppTextStyle.bodyMedium.secondary,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SdCardV2(
      child: Padding(
        padding: SdContentPaddingV2.button,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(l10n.syncScreenSyncing, style: AppTextStyle.bodyLarge),
                Text(
                  l10n.settingsSyncProgress(status.percent),
                  style: AppTextStyle.bodyMedium.secondary,
                ),
              ],
            ),
            SizedBox(height: SdContentPaddingV2.listItemGap),
            // Determinate, because the number above is: an indeterminate bar
            // next to "42%" would be saying two different things at once.
            ClipRRect(
              borderRadius: BorderRadius.circular(SdSpacingConstant.r4),
              child: LinearProgressIndicator(value: status.progress),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncNowButton extends ConsumerWidget {
  const _SyncNowButton();

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;

    await ref.read(syncControllerProvider.notifier).sync();

    // The controller swallows failures by design — every other trigger is
    // unawaited. A deliberate tap still deserves an answer.
    if (!context.mounted) return;
    if (ref.read(syncControllerProvider).phase == SyncPhase.failed) {
      SdSnackBarUtilsV2.error(context, l10n.settingsSyncFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSyncing = ref.watch(isSyncingProvider);

    return SdButtonV2(
      variant: SdButtonVariantV2.primary,
      onPressed: isSyncing ? null : () => _syncNow(context, ref),
      label: context.l10n.settingsSync,
      icon: Icons.sync,
    );
  }
}
