import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../providers.dart';

/// Optional detail fields, deliberately kept out of the 3-tap flow.
/// Opened empty right after logging, or prefilled when editing from the
/// attack detail screen.
class AttackDetailsSheet extends HookConsumerWidget {
  const AttackDetailsSheet({
    required this.attackId,
    this.initialSymptoms = const [],
    this.initialTriggers = const [],
    this.initialNotes,
    super.key,
  });

  final String attackId;
  final List<String> initialSymptoms;
  final List<String> initialTriggers;
  final String? initialNotes;

  List<String> _split(String input) =>
      input.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final symptomsController = useTextEditingController(
      text: initialSymptoms.join(', '),
    );
    final triggersController = useTextEditingController(
      text: initialTriggers.join(', '),
    );
    final notesController = useTextEditingController(text: initialNotes ?? '');

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

    return SdSheetContentV2(
      title: l10n.detailsTitle,
      closeTooltip: l10n.commonClose,
      confirmTooltip: l10n.commonDone,
      // Overwriting what is already on the attack, not adding a first
      // answer — so the commit is the pencil, not the tick.
      action: SdSheetActionV2.edit,
      onConfirm: save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: symptomsController,
            decoration: InputDecoration(
              labelText: l10n.detailsSymptomsLabel,
              hintText: l10n.detailsSymptomsHint,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          TextField(
            controller: triggersController,
            decoration: InputDecoration(
              labelText: l10n.detailsTriggersLabel,
              hintText: l10n.detailsTriggersHint,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.detailsNotesLabel),
          ),
        ],
      ),
    );
  }
}

/// Presents the details form as a scroll-controlled bottom sheet (see
/// CLAUDE.md § Code style, "Bottom sheets and dialogs").
extension AttackDetailsSheetExt on AttackDetailsSheet {
  Future<void> show(BuildContext context) => showSdBottomSheetV2<void>(
    context,
    isScrollControlled: true,
    builder: (_) => this,
  );
}
