import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../medications/providers.dart';

/// Whether a reminder makes a sound when it fires, on the screen where the
/// user is already looking at what the app has been telling them.
///
/// It says "reminder", not "notification", on purpose: a pressure alert's
/// sound is set by the server that sends the push, so this switch cannot
/// speak for it — and the subtitle says where that one is changed instead.
class ReminderSoundTile extends ConsumerWidget {
  const ReminderSoundTile({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref.read(reminderSoundProvider.notifier).setEnabled(value);
    } catch (_) {
      // The controller already logged it; the user needs the outcome.
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, context.l10n.reminderSoundFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(reminderSoundProvider);

    return SwitchListTile(
      secondary: SdIconV2(
        icon: enabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
      ),
      title: Text(
        context.l10n.reminderSoundTitle,
        style: AppTextStyle.bodyLarge,
      ),
      subtitle: Text(
        context.l10n.reminderSoundSubtitle,
        style: AppTextStyle.bodyMedium.secondary,
      ),
      value: enabled,
      onChanged: (bool value) => _toggle(context, ref, value),
    );
  }
}
