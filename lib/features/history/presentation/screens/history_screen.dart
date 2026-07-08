import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/head_location_label.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final attacks = ref.watch(attacksStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: switch (attacks) {
        AsyncData(value: final list) when list.isEmpty => Center(
          child: Text(l10n.historyEmpty),
        ),
        AsyncData(value: final list) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _AttackTile(attack: list[index], l10n: l10n),
        ),
        AsyncError() => Center(child: Text(l10n.historyEmpty)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _AttackTile extends StatelessWidget {
  const _AttackTile({required this.attack, required this.l10n});

  final Attack attack;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateFormat.yMMMd()
        .add_jm()
        .format(attack.startedAt.toLocal());
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.18),
          child: Text(
            '${attack.intensity}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        title: Text(attack.location.label(l10n)),
        subtitle: Text(
          attack.medicationName == null
              ? when
              : '$when · ${attack.medicationName}',
        ),
      ),
    );
  }
}
