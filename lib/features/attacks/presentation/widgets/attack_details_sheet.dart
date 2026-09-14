import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/symptom_tag_label.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/comma_list_utils.dart';
import '../../../../core/widgets/daily_factor_picker.dart';
import '../../../../core/widgets/icon_option_grid.dart';
import '../../../daily_log/domain/enums/daily_factor.dart';
import '../../../daily_log/providers.dart';
import '../../domain/enums/symptom_tag.dart';
import '../../providers.dart';

/// Optional detail fields, deliberately kept out of the 3-tap flow.
///
/// Symptoms and triggers are picked, not typed: free text cannot be counted,
/// and a keyboard mid-attack is a control nobody finishes. What is typed still
/// survives — the "other" field writes into the same column, beside the ids.
class AttackDetailsSheet extends HookConsumerWidget {
  const AttackDetailsSheet({
    required this.attackId,
    this.startedAt,
    this.initialSymptoms = const [],
    this.initialTriggers = const [],
    this.initialNotes,
    super.key,
  });

  final String attackId;

  /// The attack's own day, which is the day a trigger belongs to. Null only where the caller has the id alone; the check-in offer is then absent.
  final DateTime? startedAt;

  final List<String> initialSymptoms;
  final List<String> initialTriggers;
  final String? initialNotes;

  /// How far back a trigger may still be written onto a day's check-in, matching the check-in's own backfill window.
  static const int checkInBackfillDays = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final symptomTags = useState<Set<SymptomTag>>(<SymptomTag>{
      for (final String s in initialSymptoms)
        if (SymptomTag.tryParse(s) case final SymptomTag tag) tag,
    });
    final triggerFactors = useState<Set<DailyFactor>>(<DailyFactor>{
      for (final String t in initialTriggers)
        if (DailyFactor.tryParse(t) case final DailyFactor factor) factor,
    });
    // Only what the chips do not already say, so a word is never on screen twice.
    final symptomsController = useTextEditingController(
      text: CommaListUtils.join(
        initialSymptoms
            .where((String s) => SymptomTag.tryParse(s) == null)
            .toList(),
      ),
    );
    final triggersController = useTextEditingController(
      text: CommaListUtils.join(
        initialTriggers
            .where((String t) => DailyFactor.tryParse(t) == null)
            .toList(),
      ),
    );
    final notesController = useTextEditingController(text: initialNotes ?? '');
    final alsoOnCheckIn = useState<bool>(true);

    final DateTime? day = startedAt?.toLocal();
    final bool canOfferCheckIn =
        day != null &&
        DateTime.now().difference(day).inDays < checkInBackfillDays;

    Future<void> save() async {
      final notes = notesController.text.trim();
      final List<DailyFactor> factors = triggerFactors.value.toList();

      await ref
          .read(attackRepositoryProvider)
          .updateDetails(
            attackId,
            symptoms: <String>[
              for (final SymptomTag tag in symptomTags.value) tag.name,
              ...CommaListUtils.split(symptomsController.text),
            ],
            triggers: <String>[
              for (final DailyFactor factor in factors) factor.name,
              ...CommaListUtils.split(triggersController.text),
            ],
            notes: notes.isEmpty ? null : notes,
          );

      // The half that makes a trigger gradeable: without the same factor on the day, the map has nothing to compare it against.
      if (canOfferCheckIn && alsoOnCheckIn.value && factors.isNotEmpty) {
        await ref
            .read(dailyLogRepositoryProvider)
            .addFactorsToDay(day, factors);
      }

      if (context.mounted) Navigator.of(context).pop();
    }

    return SdSheetContentV2(
      title: l10n.detailsTitle,
      closeTooltip: l10n.commonClose,
      // Overwrites an existing answer, not a first one — "Update", not "Save".
      confirmLabel: l10n.commonUpdate,
      onConfirm: save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(text: l10n.detailsSymptomsLabel),
          IconOptionGrid(
            options: <IconOption>[
              for (final SymptomTag tag in SymptomTag.values)
                IconOption(
                  label: tag.label(l10n),
                  icon: _symptomIcons[tag]!,
                  selected: symptomTags.value.contains(tag),
                  onToggled: () => symptomTags.value = _toggled(
                    symptomTags.value,
                    tag,
                  ),
                ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdTextFieldV2(
            controller: symptomsController,
            label: l10n.detailsSymptomsOther,
            hint: l10n.detailsSymptomsHint,
          ),
          SizedBox(height: SdSpacingConstant.h20),
          _SectionLabel(text: l10n.detailsTriggersLabel),
          DailyFactorPicker(
            selected: triggerFactors.value,
            onToggled: (DailyFactor factor) =>
                triggerFactors.value = _toggled(triggerFactors.value, factor),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdTextFieldV2(
            controller: triggersController,
            label: l10n.detailsTriggersOther,
            hint: l10n.detailsTriggersHint,
          ),
          if (canOfferCheckIn) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h12),
            // Outlined like every other single control on a surface of readings (see HealthConnectionTile).
            Container(
              decoration: BoxDecoration(
                border: SdOutlineV2.border(context),
                borderRadius: SdOutlineV2.borderRadius,
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: SdSpacingConstant.w12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: SdOutlineV2.borderRadius,
                ),
                title: Text(
                  l10n.detailsAlsoOnCheckIn,
                  style: AppTextStyle.bodyLarge,
                ),
                subtitle: Text(
                  l10n.detailsAlsoOnCheckInBody,
                  style: AppTextStyle.bodySmall.secondary,
                ),
                value: alsoOnCheckIn.value,
                onChanged: (bool value) => alsoOnCheckIn.value = value,
              ),
            ),
          ],
          SizedBox(height: SdSpacingConstant.h20),
          SdTextFieldV2(
            controller: notesController,
            label: l10n.detailsNotesLabel,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  static const Map<SymptomTag, IconData> _symptomIcons =
      <SymptomTag, IconData>{
        SymptomTag.nausea: AppIconConstant.symptomNausea,
        SymptomTag.vomiting: AppIconConstant.symptomVomiting,
        SymptomTag.lightSensitivity: AppIconConstant.symptomLightSensitivity,
        SymptomTag.soundSensitivity: AppIconConstant.symptomSoundSensitivity,
        SymptomTag.smellSensitivity: AppIconConstant.symptomSmellSensitivity,
        SymptomTag.dizziness: AppIconConstant.symptomDizziness,
        SymptomTag.neckPain: AppIconConstant.symptomNeckPain,
        SymptomTag.blurredVision: AppIconConstant.symptomBlurredVision,
      };

  static Set<T> _toggled<T>(Set<T> current, T value) => <T>{
    ...current.where((T v) => v != value),
    if (!current.contains(value)) value,
  };
}

/// The heading over a chip grid. Not `SdSheetContentV2`'s title — the sheet has one of those already, and these are its two halves.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: SdSpacingConstant.h8),
    child: Text(text, style: AppTextStyle.labelLarge.secondary),
  );
}

/// Presents the details form as a scroll-controlled bottom sheet (see CLAUDE.md § Code style, "Bottom sheets and dialogs").
extension AttackDetailsSheetExt on AttackDetailsSheet {
  Future<void> show(BuildContext context) => showSdBottomSheetV2<void>(
    context,
    isScrollControlled: true,
    builder: (_) => this,
  );
}
