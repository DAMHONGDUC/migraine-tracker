import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/correlation_result.dart';
import 'insight_progress_body.dart';
import 'insight_settling_note.dart';

part 'correlation_body_insight.dart';
part 'correlation_body_no_variation.dart';
part 'correlation_body_progress.dart';
part 'correlation_body_teaser.dart';

/// What the correlation analysis found, without a card around it — the summary card on Insights and the detail screen both draw this.
class CorrelationBody extends ConsumerWidget {
  const CorrelationBody({required this.result, super.key});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref.watch(hasPremiumProvider);

    return switch (result) {
      // Nothing carries weather yet — there is no figure, for anyone.
      CorrelationInsufficientData() => _Progress(
        result: result,
        icon: AppIconConstant.correlation,
      ),
      // Free: how far off the insight is, and premium is the door.
      _ when !hasPremium && result.isPreliminary => _Progress(
        result: result,
        icon: AppIconConstant.locked,
      ),
      // Free, enough data: teased, never computed into the tree.
      _ when !hasPremium => const _Teaser(),
      CorrelationNoVariation() => _NoVariation(),
      final CorrelationInsight r => _Insight(result: r),
    };
  }
}
