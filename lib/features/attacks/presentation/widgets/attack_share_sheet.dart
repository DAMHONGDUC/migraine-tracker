import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/attack.dart';
import '../../providers.dart';
import 'attack_share_card.dart';

/// Previews the card, then hands it to the system share sheet.
///
/// **The preview is not a courtesy, it is the mechanism.** What gets captured
/// is this very boundary, so the user cannot send a card they were not shown
/// — which is the only honest way to put health data into a messaging app.
class AttackShareSheet extends ConsumerStatefulWidget {
  const AttackShareSheet({required this.attack, super.key});

  final Attack attack;

  static Future<void> show(BuildContext context, Attack attack) =>
      showSdBottomSheetV2<void>(
        context,
        builder: (_) => AttackShareSheet(attack: attack),
      );

  @override
  ConsumerState<AttackShareSheet> createState() => _AttackShareSheetState();
}

class _AttackShareSheetState extends ConsumerState<AttackShareSheet> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);

    final bool shared = await ref
        .read(attackShareControllerProvider)
        .share(boundaryKey: _boundaryKey, attackId: widget.attack.id);

    if (!mounted) return;

    setState(() => _sharing = false);
    if (shared) {
      Navigator.of(context).pop();
    } else {
      SdSnackBarUtilsV2.error(context, context.l10n.attackShareFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SdSheetContentV2(
      title: l10n.attackShareTitle,
      closeTooltip: l10n.commonClose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RepaintBoundary(
            key: _boundaryKey,
            child: AttackShareCard(attack: widget.attack),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          Text(
            l10n.attackSharePrivacy,
            textAlign: TextAlign.center,
            style: AppTextStyle.labelSmall.secondary,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdButtonV2(
            variant: SdButtonVariantV2.primary,
            label: l10n.attackShareAction,
            icon: Icons.ios_share,
            // Disabled rather than spinning: the capture is a frame or two,
            // and a spinner that flashes for 30ms reads as a glitch.
            onPressed: _sharing ? null : _share,
          ),
        ],
      ),
    );
  }
}
