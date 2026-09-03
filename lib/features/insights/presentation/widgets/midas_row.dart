import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/midas_grade_label.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/midas_score.dart';
import '../../providers.dart';

/// The door to the MIDAS questionnaire, on the screen that produces the report the score rides in.
///
/// It lives beside the export rather than on an Insights tab because the score
/// is not an analysis the app performs — it is an answer the user gives, and
/// the only place it is read is the doctor report.
class MidasRow extends ConsumerWidget {
  const MidasRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final MidasEntry? latest = ref.watch(latestMidasProvider).value;

    return SettingsTile(
      icon: AppIconConstant.document,
      title: l10n.midasRowTitle,
      value: latest == null
          ? l10n.midasNever
          : '${l10n.midasScore(latest.score)} · '
                '${latest.grade.label(l10n)}',
      onTap: () => context.pushNamed<void>(AppRoutes.midas.name),
    );
  }
}
