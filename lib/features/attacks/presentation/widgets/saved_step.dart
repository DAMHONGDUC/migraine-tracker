import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import 'attack_details_sheet.dart';

/// Confirmation after the attack is saved. Calm, static — no flashing.
class SavedStep extends StatelessWidget {
  const SavedStep({required this.attackId, required this.onDone, super.key});

  final String attackId;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(l10n.logSavedTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              l10n.logSavedSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AttackDetailsSheet(attackId: attackId),
              ),
              child: Text(l10n.logAddDetails),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onDone, child: Text(l10n.logDone)),
          ],
        ),
      ),
    );
  }
}
