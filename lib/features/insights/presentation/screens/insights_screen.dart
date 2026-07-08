import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../providers.dart';
import '../widgets/correlation_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(correlationResultProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.insightsTitle)),
      body: switch (result) {
        AsyncData(value: final value) => ListView(
          padding: EdgeInsets.all(16.w),
          children: [CorrelationCard(result: value)],
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
