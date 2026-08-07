import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../features/auth/providers.dart';
import '../../../features/sync/domain/entities/sync_status.dart';
import '../../../features/sync/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../theme/app_text_style.dart';
import '../settings_tile.dart';

/// The short version of sync, in Settings' "Your data" — one more thing that
/// happens to the user's data, alongside export and delete.
///
/// A plain row that leads to `SyncScreen`, except while a pass is running:
/// then the end of the row carries a spinner and how far it has got, so the
/// state is visible without opening anything. Everything else about sync —
/// the last run, the manual button — lives on that screen (hard rule 12).
///
/// Absent without an account, because there would be nowhere to sync to.
class SyncSettingsTile extends ConsumerWidget {
  const SyncSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isSignedInProvider)) return const SizedBox.shrink();

    final SyncStatus status = ref.watch(syncControllerProvider);

    return SettingsTile(
      icon: Icons.sync,
      title: context.l10n.settingsSync,
      // Only while syncing; otherwise the row falls back to the plain chevron
      // that says "this leads somewhere", which is what it now does.
      trailing: status.isSyncing
          ? _SyncProgress(percent: status.percent)
          : null,
      onTap: () => context.pushNamed(AppRoutes.sync.name),
    );
  }
}

/// Spinner then percentage, in the row's trailing slot.
///
/// Both, not either: the spinner says the pass is alive, the number says how
/// far — a row that only spins cannot tell a slow sync from a stuck one.
class _SyncProgress extends StatelessWidget {
  const _SyncProgress({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: SdSpacingConstant.r20,
          height: SdSpacingConstant.r20,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: SdSpacingConstant.w8),
        Text(
          context.l10n.settingsSyncProgress(percent),
          style: AppTextStyle.bodyMedium.secondary,
        ),
      ],
    );
  }
}
