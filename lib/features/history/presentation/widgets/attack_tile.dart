import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:system_design/v2/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_location_label.dart';
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
    return Card(
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
          attack.location.label(context.l10n),
          style: AppTextStyle.bodyLarge,
        ),
        subtitle: Text(
          attack.medicationName == null
              ? when
              : '$when · ${attack.medicationName}',
          style: AppTextStyle.bodyMedium.secondary,
        ),
        trailing: SdIconV2(
        icon:  Icons.chevron_right,
          size: SdSpacingV2.r20,
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
