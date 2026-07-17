import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../providers.dart';

/// Optional detail fields, deliberately kept out of the 3-tap flow.
class AttackDetailsSheet extends HookConsumerWidget {
  const AttackDetailsSheet({required this.attackId, super.key});

  final String attackId;

  List<String> _split(String input) => input
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final symptomsController = useTextEditingController();
    final triggersController = useTextEditingController();
    final notesController = useTextEditingController();

    Future<void> save() async {
      final notes = notesController.text.trim();
      await ref
          .read(attackRepositoryProvider)
          .updateDetails(
            attackId,
            symptoms: _split(symptomsController.text),
            triggers: _split(triggersController.text),
            notes: notes.isEmpty ? null : notes,
          );
      if (context.mounted) Navigator.of(context).pop();
    }

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacingConstant.w24,
        right: AppSpacingConstant.w24,
        top: AppSpacingConstant.h24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacingConstant.h24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.detailsTitle, style: context.textTheme.titleLarge),
          SizedBox(height: AppSpacingConstant.h16),
          TextField(
            controller: symptomsController,
            decoration: InputDecoration(
              labelText: l10n.detailsSymptomsLabel,
              hintText: l10n.detailsSymptomsHint,
            ),
          ),
          SizedBox(height: AppSpacingConstant.h12),
          TextField(
            controller: triggersController,
            decoration: InputDecoration(
              labelText: l10n.detailsTriggersLabel,
              hintText: l10n.detailsTriggersHint,
            ),
          ),
          SizedBox(height: AppSpacingConstant.h12),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.detailsNotesLabel),
          ),
          SizedBox(height: AppSpacingConstant.h24),
          FilledButton(onPressed: save, child: Text(l10n.detailsSave)),
        ],
      ),
    );
  }
}
