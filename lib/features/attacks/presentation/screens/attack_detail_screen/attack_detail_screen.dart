import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/aura_label.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/duration_label.dart';
import '../../../../../core/extensions/exertion_level_label.dart';
import '../../../../../core/extensions/head_region_label.dart';
import '../../../../../core/extensions/medication_effect_label.dart';
import '../../../../../core/extensions/symptom_tag_label.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/weather/weather_card.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/attack.dart';
import '../../../domain/enums/aura_type.dart';
import '../../../domain/enums/exertion_level.dart';
import '../../../domain/enums/head_region.dart';
import '../../../domain/enums/medication_effect.dart';
import '../../../providers.dart';
import '../../widgets/attack_details_sheet.dart';
import '../../widgets/attack_duration_sheet.dart';
import '../../widgets/attack_share_sheet.dart';
import '../../widgets/attack_start_sheet.dart';
import '../../widgets/aura_picker_sheet.dart';
import '../../widgets/exertion_picker_sheet.dart';
import '../../widgets/head_diagram.dart';
import '../../widgets/intensity_disc.dart';
import '../../widgets/intensity_sheet.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/medication_effect_sheet.dart';
import '../../widgets/medication_picker_sheet.dart';
import '../../widgets/medication_timing_sheet.dart';

part 'attack_detail_screen_details_section.dart';
part 'attack_detail_screen_editable_row.dart';
part 'attack_detail_screen_header.dart';
part 'attack_detail_screen_location_diagram.dart';
part 'attack_detail_screen_read_only_row.dart';
part 'attack_detail_screen_section.dart';
part 'attack_detail_screen_weather_section.dart';

/// View and correct a logged attack. Reachable from History; the 3-tap log flow itself stays untouched.
class AttackDetailScreen extends HookConsumerWidget {
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
          regions: attack.regions,
          medicationName: attack.medicationName,
        );
  }

  Future<void> _editLocation(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    final List<HeadRegion>? picked = await LocationPickerSheet(
      selected: attack.regions,
    ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateCore(
          attack.id,
          intensity: attack.intensity,
          regions: picked,
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
          regions: attack.regions,
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

  /// The one edit that also invalidates the weather: the snapshot belonged to the old instant.
  Future<void> _editStartedAt(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    final ({DateTime startedAt})? picked = await AttackStartSheet(
      startedAt: attack.startedAt,
      endedAt: attack.endedAt,
    ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateStartedAt(attack.id, picked.startedAt);
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

  /// Three states, and the row has to tell them apart: nothing said, a dose with no relief yet, and the answer the row exists for.
  String _timingLabel(Attack attack, AppLocalizations l10n) {
    final Duration? relief = attack.timeToRelief;
    final DateTime? takenAt = attack.medicationTakenAt;

    if (relief != null) return relief.label(l10n);
    if (takenAt == null) return l10n.medicationTimingNotRecorded;
    return l10n.medicationTimingTakenOnly(
      takenAt.difference(attack.startedAt).label(l10n),
    );
  }

  Future<void> _editMedicationTiming(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    // Wrapped so clearing both answers is distinguishable from dismissing.
    final ({DateTime? takenAt, DateTime? reliefAt})? picked =
        await MedicationTimingSheet(
          startedAt: attack.startedAt,
          takenAt: attack.medicationTakenAt,
          reliefAt: attack.reliefAt,
        ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateMedicationTiming(
          attack.id,
          takenAt: picked.takenAt,
          reliefAt: picked.reliefAt,
        );
  }

  Future<void> _editAura(
    BuildContext context,
    WidgetRef ref,
    Attack attack,
  ) async {
    // Wrapped so a recorded "no aura" (an empty list) stays distinguishable from clearing the answer, and both from dismissing the sheet.
    final ({List<AuraType>? aura})? picked = await AuraPickerSheet(
      selected: attack.aura,
    ).show(context);

    if (picked == null) return;
    await ref
        .read(attackDetailControllerProvider)
        .updateAura(attack.id, picked.aura);
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

    // The header's two facts move into the bar once the header itself has scrolled out from under it, so what the screen is about never leaves the screen.
    final ScrollController controller = useScrollController();
    final ValueNotifier<bool> collapsed = useState(false);

    useEffect(() {
      void onScroll() => collapsed.value = controller.offset > _Header.height;

      controller.addListener(onScroll);

      return () => controller.removeListener(onScroll);
    }, <Object?>[controller]);

    return SdScaffoldV2(
      title: _ScrollAwareTitle(
        collapsed: collapsed,
        attack: attack.value,
        title: Text(l10n.attackDetailTitle, style: AppTextStyle.titleLarge),
      ),
      actions: [
        // Only once the attack has actually loaded — a share button over a deleted or still-loading record has nothing to render.
        if (attack.value case final Attack loaded) ...[
          SdAppBarButtonV2(
            icon: AppIconConstant.share,
            color: AppColors.secondary,
            tooltip: l10n.attackShareTitle,
            onPressed: () => AttackShareSheet.show(context, loaded),
          ),
          SdHorizontalSpacingV2(),
        ],
        SdAppBarButtonV2(
          icon: AppIconConstant.delete,
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
          controller: controller,
          padding: SdContentPaddingV2.screen(context),
          children: [
            _Header(attack: a),
            SizedBox(height: SdSpacingConstant.h16),
            _LocationDiagram(regions: a.regions),
            SizedBox(height: SdSpacingConstant.h16),
            _Section(
              children: [
                // First, because every other reading on this screen hangs off it — the weather snapshot above all.
                _EditableRow(
                  label: l10n.attackDetailStartedAt,
                  value: DateFormat.yMMMd(
                    l10n.localeName,
                  ).add_jm().format(a.startedAt.toLocal()),
                  onTap: () => _editStartedAt(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.attackDetailIntensity,
                  value: '${a.intensity}',
                  swatch: AppColors.intensity(a.intensity),
                  onTap: () => _editIntensity(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.attackDetailLocation,
                  value: a.regions.label(l10n),
                  onTap: () => _editLocation(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.attackDetailMedication,
                  value: a.medicationName ?? l10n.logNoMedication,
                  onTap: () => _editMedication(context, ref, a),
                ),
                // Only where a medication was actually taken: asking whether "no medication" helped is a question with no answer.
                if (a.medicationName != null)
                  _EditableRow(
                    label: l10n.attackDetailMedicationEffect,
                    value:
                        a.medicationEffect?.label(l10n) ??
                        l10n.medicationEffectNotRecorded,
                    onTap: () => _editMedicationEffect(context, ref, a),
                  ),
                // Beside the effect row and for the same reason: with nothing taken there is no dose to time.
                if (a.medicationName != null)
                  _EditableRow(
                    label: l10n.attackDetailMedicationTiming,
                    value: _timingLabel(a, l10n),
                    onTap: () => _editMedicationTiming(context, ref, a),
                  ),
                // Above duration, because aura runs BEFORE the pain and the rows read in the order the attack happened.
                _EditableRow(
                  label: l10n.attackDetailAura,
                  // Keep unanswered, no-aura and aura states distinct.
                  value: a.aura.label(l10n),
                  onTap: () => _editAura(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.attackDetailDuration,
                  // Null means the attack has no recorded end time.
                  value:
                      a.duration?.label(l10n) ?? l10n.attackDurationNotRecorded,
                  onTap: () => _editDuration(context, ref, a),
                ),
                _EditableRow(
                  label: l10n.detailsExertionLabel,
                  // Attacks logged before the step existed read as "None", which is the same answer their blank column means.
                  value: (a.exertionLevel ?? ExertionLevel.none).label(l10n),
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
        // The detail is a stack of rows and it is always the same stack, so the wait is drawn in that shape rather than spun for.
        _ => Padding(
          padding: SdContentPaddingV2.screen(context),
          child: const SdListSkeletonV2(),
        ),
      },
    );
  }
}
