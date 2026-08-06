import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../features/auth/providers.dart';
import '../../../features/sync/domain/entities/sync_status.dart';
import '../../../features/sync/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../settings_tile.dart';

/// The one place sync is visible or steerable (hard rule 12): a row in
/// Settings' "Your data" that runs a sync on tap and shows a spinner while
/// one is in flight. Not a section of its own — sync is one more thing that
/// happens to the user's data, alongside export and delete.
///
/// Absent without an account, because there is nowhere to sync to. Sync is
/// automatic — this row exists for a deliberate retry, never as a step the
/// user is expected to remember.
class SyncSettingsTile extends ConsumerWidget {
  const SyncSettingsTile({super.key});

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;

    await ref.read(syncControllerProvider.notifier).sync();

    // The controller swallows failures by design — every other trigger is
    // unawaited. A deliberate tap still deserves an answer, so the outcome is
    // read back off the state rather than caught.
    if (!context.mounted) return;
    if (ref.read(syncControllerProvider).phase == SyncPhase.failed) {
      SdSnackBarUtilsV2.error(context, l10n.settingsSyncFailed);
    }
  }

  /// When it last finished, or why it did not. Null while a pass is running,
  /// because the spinner is already saying so.
  String? _status(BuildContext context, SyncStatus status) {
    final AppLocalizations l10n = context.l10n;
    final DateTime? at = status.lastSyncedAt;

    if (status.isSyncing) return null;
    if (status.phase == SyncPhase.failed) return l10n.settingsSyncStatusFailed;
    if (at == null) return l10n.settingsSyncStatusNever;
    // Time alone once it happened today — the date would be noise on the row
    // it shares with the title.
    return DateUtils.isSameDay(at, DateTime.now())
        ? DateFormat.Hm(l10n.localeName).format(at)
        : DateFormat.yMMMd(l10n.localeName).format(at);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isSignedInProvider)) return const SizedBox.shrink();

    final SyncStatus status = ref.watch(syncControllerProvider);

    return SettingsTile(
      icon: Icons.sync,
      title: context.l10n.settingsSync,
      value: _status(context, status),
      // Same spinner-in-the-trailing-slot as the dev tiles; reverts to the
      // status + chevron once the pass is done.
      trailing: status.isSyncing
          ? SizedBox(
              width: SdSpacingConstant.r20,
              height: SdSpacingConstant.r20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: status.isSyncing ? null : () => _syncNow(context, ref),
    );
  }
}
