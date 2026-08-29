import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/exertion_correlation_result.dart';
import 'insight_progress_body.dart';
import 'insight_settling_note.dart';

part 'exertion_correlation_body_insight.dart';
part 'exertion_correlation_body_no_variation.dart';

/// What the exertion self-report found, without a card around it.
///
/// Free, unlike the step body beside it: exertion is self-reported, not read
/// from HealthKit, so there is no premium data boundary to gate.
class ExertionCorrelationBody extends StatelessWidget {
  const ExertionCorrelationBody({required this.result, super.key});

  final ExertionCorrelationResult result;

  @override
  Widget build(BuildContext context) {
    return switch (result) {
      // No padlock: this body is free, so nothing here is ever locked.
      final ExertionInsufficientData r => InsightProgressBody(
        icon: AppIconConstant.correlation,
        message: context.l10n.insightsExertionInsufficientData(
          r.requiredAttacks - r.attacksAnalyzed,
        ),
        progress: r.attacksAnalyzed / r.requiredAttacks,
        caption: context.l10n.insightsExertionProgressCaption(
          r.attacksAnalyzed,
          r.requiredAttacks,
        ),
      ),
      ExertionNoVariation() => _NoVariation(),
      final ExertionInsight r => _Insight(result: r),
    };
  }
}
