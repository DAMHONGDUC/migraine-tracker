import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_location_label.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';
import '../../domain/enums/history_view_mode.dart';
import '../../domain/services/weekly_buckets.dart';
import '../controllers/history_controller.dart';
import '../widgets/history_filter_sheet.dart';
import '../widgets/history_view_toggle.dart';
import '../widgets/weekly_frequency_chart.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allAttacks = ref.watch(attacksStreamProvider);
    final filtered = ref.watch(filteredAttacksProvider);
    final mode = ref.watch(historyViewModeProvider);
    final period = ref.watch(historyPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          HistoryViewToggle(
            mode: mode,
            onChanged: ref.read(historyViewModeProvider.notifier).select,
          ),
          SizedBox(width: AppSpacingConstant.w12),
        ],
      ),
      body: switch (allAttacks) {
        AsyncData(value: final all) when all.isEmpty => Center(
          child: Text(l10n.historyEmpty),
        ),
        AsyncData() => Builder(
          builder: (context) {
            final list = switch (filtered) {
              AsyncData(value: final value) => value,
              _ => const <Attack>[],
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shared filter, right below the app bar: closed = current
                // value at a glance, tap = bottom sheet picker.
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacingConstant.w16, AppSpacingConstant.h8, AppSpacingConstant.w16, AppSpacingConstant.h12),
                  child: HistoryFilterChip(
                    selected: period,
                    onSelected:
                        ref.read(historyPeriodProvider.notifier).select,
                  ),
                ),
                Expanded(
                  // IndexedStack keeps BOTH views alive so switching modes
                  // preserves state (list scroll position, chart layout).
                  child: IndexedStack(
                    index: mode == HistoryViewMode.list ? 0 : 1,
                    children: [
                      _AttackList(attacks: list),
                      _ChartView(attacks: list),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        AsyncError() => Center(child: Text(l10n.historyEmpty)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Chart mode — same filtered data as the list.
class _ChartView extends StatelessWidget {
  const _ChartView({required this.attacks});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context) {
    if (attacks.isEmpty) {
      return Center(child: Text(context.l10n.historyEmptyFiltered));
    }
    return ListView(
      padding: EdgeInsets.all(AppSpacingConstant.w16),
      children: [
        WeeklyFrequencyChart(
          buckets: weeklyBuckets(attacks, now: DateTime.now()),
        ),
        SizedBox(height: AppSpacingConstant.h12),
        Text(
          context.l10n.historyAttackCount(attacks.length),
          style: context.textTheme.titleSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AttackList extends StatelessWidget {
  const _AttackList({required this.attacks});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context) {
    if (attacks.isEmpty) {
      return Center(child: Text(context.l10n.historyEmptyFiltered));
    }
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacingConstant.w16),
      itemCount: attacks.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacingConstant.h8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacingConstant.h4),
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
