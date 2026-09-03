import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/health/domain/enums/health_data_kind.dart';
import '../../features/health/providers.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_text_style.dart';

/// One Apple Health source's connect switch, at the top of the card that draws
/// what it reads — sleep on the sleep tab, steps on the activity one, the cycle
/// on the daily check-in.
///
/// It lives in `core/widgets/` because three features draw it now and none of
/// them may import another's `presentation/`.
///
/// **It used to be a Settings row** (owner's call to move it). A switch two
/// screens away from the empty chart it fills is a switch nobody connects: the
/// user is looking at the reading, so the control that turns it on belongs
/// where they are looking. Settings keeps only the row that leads here.
class HealthConnectionTile extends ConsumerWidget {
  const HealthConnectionTile({
    required this.kind,
    required this.icon,
    required this.title,
    super.key,
  });

  final HealthDataKind kind;
  final IconData icon;
  final String title;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    try {
      final bool connected = await ref
          .read(healthControllerProvider.notifier)
          .setConnected(kind, value);

      if (!context.mounted || connected) return;

      SdSnackBarUtilsV2.error(context, context.l10n.healthConnectFailed);
    } catch (_) {
      // The controller already logged it; the user needs the outcome.
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, context.l10n.healthConnectFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(healthAvailableProvider)) return const SizedBox.shrink();

    final bool connected = ref.watch(healthControllerProvider).of(kind);

    // Outlined, so the one control on a card of readings reads as a control.
    // Everything else here is something the app is telling the user; this is
    // the row they can act on, and a box is what separates the two without a
    // second colour or a second weight of type.
    return Container(
      decoration: BoxDecoration(
        border: SdOutlineV2.border(context),
        borderRadius: SdOutlineV2.borderRadius,
      ),
      child: SwitchListTile(
        // Its own inset now: the card's gutter stops at the border, and content flush against a line reads as overflowing it.
        contentPadding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w12),
        shape: RoundedRectangleBorder(borderRadius: SdOutlineV2.borderRadius),
        secondary: SdIconV2(icon: icon, size: AppIconSize.medium),
        title: Text(title, style: AppTextStyle.bodyLarge),
        value: connected,
        onChanged: (bool value) => _toggle(context, ref, value),
      ),
    );
  }
}
