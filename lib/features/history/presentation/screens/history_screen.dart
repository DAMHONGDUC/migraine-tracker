import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_location_label.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';
import '../../domain/services/weekly_buckets.dart';
import '../widgets/weekly_frequency_chart.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final attacks = ref.watch(attacksStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: switch (attacks) {
        AsyncData(value: final list) when list.isEmpty => Center(
          child: Text(l10n.historyEmpty),
        ),
        AsyncData(value: final list) => ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            WeeklyFrequencyChart(
              buckets: weeklyBuckets(list, now: DateTime.now()),
            ),
            SizedBox(height: 24.h),
            for (final attack in list) ...[
              _AttackTile(attack: attack),
              SizedBox(height: 8.h),
            ],
          ],
        ),
        AsyncError() => Center(child: Text(l10n.historyEmpty)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _AttackTile extends StatelessWidget {
  const _AttackTile({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat.yMMMd(
      context.l10n.localeName,
    ).add_jm().format(attack.startedAt.toLocal());
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.colorScheme.primary.withValues(alpha: 0.18),
          child: Text(
            '${attack.intensity}',
            style: context.textTheme.titleMedium,
          ),
        ),
        title: Text(attack.location.label(context.l10n)),
        subtitle: Text(
          attack.medicationName == null
              ? when
              : '$when · ${attack.medicationName}',
        ),
      ),
    );
  }
}
