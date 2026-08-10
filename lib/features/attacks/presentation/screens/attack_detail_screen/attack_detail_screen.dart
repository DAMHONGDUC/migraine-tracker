import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/duration_label.dart';
import '../../../../../core/extensions/exertion_level_label.dart';
import '../../../../../core/extensions/head_location_label.dart';
import '../../../../../core/extensions/medication_effect_label.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/utils/signed_number_utils.dart';
import '../../../domain/entities/attack.dart';
import '../../../domain/enums/exertion_level.dart';
import '../../../domain/enums/head_location.dart';
import '../../../domain/enums/medication_effect.dart';
import '../../../providers.dart';
import '../../widgets/attack_details_sheet.dart';
import '../../widgets/attack_duration_sheet.dart';
import '../../widgets/exertion_picker_sheet.dart';
import '../../widgets/head_diagram.dart';
import '../../widgets/intensity_disc.dart';
import '../../widgets/intensity_sheet.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/medication_effect_sheet.dart';
import '../../widgets/medication_picker_sheet.dart';

part 'attack_detail_screen_details_section.dart';
part 'attack_detail_screen_editable_row.dart';
part 'attack_detail_screen_header.dart';
part 'attack_detail_screen_location_diagram.dart';
part 'attack_detail_screen_read_only_row.dart';
part 'attack_detail_screen_section.dart';
part 'attack_detail_screen_weather_section.dart';

/// View and correct a logged attack. Reachable from History; the 3-tap log
/// flow itself stays untouched.
class AttackDetailScreen extends ConsumerWidget {
  const AttackDetailScreen({required this.attackId, super.key});

  final String attackId;

  Future<void> _editIntensity(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    final int? picked = await IntensitySheet(
      initial: attack.intensity,
    ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateCore(
          attack.id,
          intensity: picked,
          location: attack.location,
          medicationName: attack.medicationName,
        );
  }

  Future<void> _editLocation(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    final HeadLocation? picked = await LocationPickerSheet(
      selected: attack.location,
    ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateCore(
          attack.id,
          intensity: attack.intensity,
          location: picked,
          medicationName: attack.medicationName,
        );
  }

  Future<void> _editMedication(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    // Wrapped so "No medication" (null) is distinguishable from dismissal.
    final ({String? name})? picked = await MedicationPickerSheet(
      selectedName: attack.medicationName,
    ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateCore(
          attack.id,
          intensity: attack.intensity,
          location: attack.location,
          medicationName: picked.name,
        );
  }

  Future<void> _editExertion(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    final ExertionLevel? picked = await ExertionPickerSheet(
      selected: attack.exertionLevel,
    ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateExertion(attack.id, picked);
  }

  Future<void> _editDuration(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    // Wrapped so clearing the answer is distinguishable from dismissing.
    final ({DateTime? endedAt})? picked = await AttackDurationSheet(
      startedAt: attack.startedAt,
      endedAt: attack.endedAt,
    ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateEndedAt(attack.id, picked.endedAt);
  }

  Future<void> _editMedicationEffect(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    // Wrapped so clearing the answer is distinguishable from dismissing.
    final ({MedicationEffect? effect})? picked = await MedicationEffectSheet(
      selected: attack.medicationEffect,
    ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateMedicationEffect(attack.id, picked.effect);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSdDialogV2<bool>(
      context,
      builder: (dialogContext) => SdDialogV2(
        title: l10n.attackDetailDeleteTitle,
        content: Text(
          l10n.attackDetailDeleteBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: [
          SdButtonV2(
            variant: SdButtonVariantV2.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsDeleteConfirmAction,
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(attackDetailControllerProvider).delete(attackId);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final attack = ref.watch(attackByIdProvider(attackId));

    return SdScaffoldV2(
      title: Text(l10n.attackDetailTitle, style: AppTextStyle.titleLarge),
      actions: [
        SdAppBarButtonV2(
          icon: Icons.delete_outline,
          color: context.colorScheme.error,
          tooltip: l10n.attackDetailDeleteTitle,
          onPressed: () => _delete(context, ref),
        ),
        SizedBox(width: SdSpacingConstant.w4),
      ],
      body: switch (attack) {
        AsyncData(value: null) || AsyncError() => Center(
          child: Text(l10n.attackDetailDeleted, style: AppTextStyle.bodyLarge),
        ),
        AsyncData(value: final a?) => ListView(
          padding: SdContentPaddingV2.screen(context),
          children: [
            _Header(attack: a),
            SizedBox(height: SdSpacingConstant.h16),
            _LocationDiagram(location: a.location),
            SizedBox(height: SdSpacingConstant.h16),
            _Section(
              children: [
                _EditableRow(
                  label: l10n.attackDetailIntensity,
                  value: '${a.intensity}',
                  swatch: AppColors.intensity(a.intensity),
                  onTap: () => _editIntensity(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.attackDetailLocation,
                  value: a.location.label(l10n),
                  onTap: () => _editLocation(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.attackDetailMedication,
                  value: a.medicationName ?? l10n.logNoMedication,
                  onTap: () => _editMedication(context, ref, a),
                ),
                // Only where a medication was actually taken: asking whether
                // "no medication" helped is a question with no answer.
                if (a.medicationName != null)
                  _EditableRow(
                    label: l10n.attackDetailMedicationEffect,
                    value:
                        a.medicationEffect?.label(l10n) ??
                        l10n.medicationEffectNotRecorded,
                    onTap: () => _editMedicationEffect(context, ref, a),
                  ),
                _EditableRow(
                  label: l10n.attackDetailDuration,
                  // Null reads as "not recorded", which is also what a still
                  // running attack looks like — the app cannot tell them
                  // apart and must not pretend it can.
                  value:
                      a.duration?.label(l10n) ?? l10n.attackDurationNotRecorded,
                  onTap: () => _editDuration(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.detailsExertionLabel,
                  // Attacks logged before the step existed read as "None",
                  // which is the same answer their blank column means.
                  value:
                      (a.exertionLevel ?? ExertionLevel.none).label(l10n),
                  onTap: () => _editExertion(context, ref, a),
                ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h16),
            _WeatherSection(attack: a),
            SizedBox(height: SdSpacingConstant.h16),
            _DetailsSection(attack: a),
          ],
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
