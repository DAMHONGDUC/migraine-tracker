import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_location_label.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';
import '../../domain/services/weekly_buckets.dart';
import '../controllers/history_controller.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/weekly_frequency_chart.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allAttacks = ref.watch(attacksStreamProvider);
    final filtered = ref.watch(filteredAttacksProvider);
    final period = ref.watch(historyPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: switch (allAttacks) {
        AsyncData(value: final all) when all.isEmpty => Center(
          child: Text(l10n.historyEmpty),
        ),
        AsyncData(value: final all) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: WeeklyFrequencyChart(
                buckets: weeklyBuckets(all, now: DateTime.now()),
              ),
            ),
            HistoryFilterBar(
              selected: period,
              onSelected: ref.read(historyPeriodProvider.notifier).select,
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _FilteredList(
                  key: ValueKey(period),
                  attacks: switch (filtered) {
                    AsyncData(value: final list) => list,
                    _ => const [],
                  },
                ),
              ),
            ),
          ],
        ),
        AsyncError() => Center(child: Text(l10n.historyEmpty)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _FilteredList extends StatelessWidget {
  const _FilteredList({required this.attacks, super.key});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context) {
    if (attacks.isEmpty) {
      return Center(child: Text(context.l10n.historyEmptyFiltered));
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      itemCount: attacks.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Text(
              context.l10n.historyAttackCount(attacks.length),
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return _AttackTile(attack: attacks[index - 1]);
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
