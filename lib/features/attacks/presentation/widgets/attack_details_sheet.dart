import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/enums/exertion_level.dart';
import '../../providers.dart';
import 'exertion_level_picker.dart';

/// Optional detail fields, deliberately kept out of the 3-tap flow.
/// Opened empty right after logging, or prefilled when editing from the
/// attack detail screen.
class AttackDetailsSheet extends HookConsumerWidget {
  const AttackDetailsSheet({
    required this.attackId,
    this.initialSymptoms = const [],
    this.initialTriggers = const [],
    this.initialNotes,
    this.initialExertionLevel,
    super.key,
  });

  final String attackId;
  final List<String> initialSymptoms;
  final List<String> initialTriggers;
  final String? initialNotes;
  final ExertionLevel? initialExertionLevel;

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
    final exertionLevel = useState<ExertionLevel?>(initialExertionLevel);

    Future<void> save() async {
      final notes = notesController.text.trim();
      await ref
          .read(attackRepositoryProvider)
          .updateDetails(
            attackId,
            symptoms: _split(symptomsController.text),
            triggers: _split(triggersController.text),
            notes: notes.isEmpty ? null : notes,
            exertionLevel: exertionLevel.value,
          );
      if (context.mounted) Navigator.of(context).pop();
    }

    return SdSheetContentV2(
      title: l10n.detailsTitle,
      closeTooltip: l10n.commonClose,
      confirmTooltip: l10n.commonDone,
      // Overwrites an existing answer, not a first one — pencil, not tick.
      action: SdSheetActionV2.edit,
      onConfirm: save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SdTextFieldV2(
            controller: symptomsController,
            label: l10n.detailsSymptomsLabel,
            hint: l10n.detailsSymptomsHint,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdTextFieldV2(
            controller: triggersController,
            label: l10n.detailsTriggersLabel,
            hint: l10n.detailsTriggersHint,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdTextFieldV2(
            controller: notesController,
            label: l10n.detailsNotesLabel,
            maxLines: 3,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Text(l10n.detailsExertionLabel, style: AppTextStyle.bodyMedium),
          SizedBox(height: SdSpacingConstant.h8),
          ExertionLevelPicker(
            selected: exertionLevel.value,
            onSelected: (value) => exertionLevel.value = value,
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
