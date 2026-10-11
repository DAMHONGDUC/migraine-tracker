import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/correlation_result.dart';
import 'insight_progress_body.dart';
import 'insight_settling_note.dart';

part 'correlation_body_insight.dart';
part 'correlation_body_no_variation.dart';
part 'correlation_body_progress.dart';

/// What the correlation analysis found, without a card around it — the summary card on Insights and the detail screen both draw this.
class CorrelationBody extends StatelessWidget {
  const CorrelationBody({required this.result, super.key});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context) {
    return switch (result) {
      // Nothing carries weather yet — there is no figure, for anyone.
      CorrelationInsufficientData() => _Progress(result: result),
      CorrelationNoVariation() => _NoVariation(),
      final CorrelationInsight r => _Insight(result: r),
    };
  }
}
