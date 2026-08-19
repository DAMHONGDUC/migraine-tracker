import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_region_label.dart';
import '../../../../core/extensions/intensity_severity_label.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../attacks/domain/entities/attack.dart';

/// One attack row, shared by the list and calendar views. Taps through to
/// the attack detail screen.
class AttackTile extends StatelessWidget {
  const AttackTile({required this.attack, super.key});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat.yMMMd(
      context.l10n.localeName,
    ).add_jm().format(attack.startedAt.toLocal());
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 8),
          child: child,
        ),
      ),
      child: _card(context, when),
    );
  }

  Widget _card(BuildContext context, String when) {
    return SdCardV2(
      child: ListTile(
        // The avatar shows a bare number — tell VoiceOver what it means.
        leading: Semantics(
          label: context.l10n.a11yIntensityLabel(
            attack.intensity,
            attack.intensity.severityLabel(context.l10n),
          ),
          excludeSemantics: true,
          child: CircleAvatar(
            backgroundColor: context.colorScheme.primary.withValues(
              alpha: 0.18,
            ),
            child: Text('${attack.intensity}', style: AppTextStyle.titleMedium),
          ),
        ),
        title: Text(
          attack.regions.label(context.l10n),
          style: AppTextStyle.bodyLarge,
          maxLines: 1,
          // An attack can name every area of the head, and the row is one
          // line: the tile is a way in, the detail screen is the reading.
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          attack.medicationName == null
              ? when
              : '$when · ${attack.medicationName}',
          style: AppTextStyle.bodyMedium.secondary,
        ),
        trailing: SdIconV2(
          icon: Icons.chevron_right,
          size: SdSpacingConstant.r20,
          color: context.colorScheme.onSurfaceVariant,
        ),
        onTap: () => context.pushNamed(
          AppRoutes.attack.name,
          pathParameters: {AppRoutes.attackIdParam: attack.id},
        ),
      ),
    );
  }
}
