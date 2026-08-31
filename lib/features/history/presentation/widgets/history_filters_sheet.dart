import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/attack_filter_labels.dart';
import '../../../../core/extensions/chart_labels.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/exertion_level_label.dart';
import '../../../../core/extensions/head_region_label.dart';
import '../../../../core/extensions/medication_effect_label.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../../../attacks/domain/enums/head_region.dart';
import '../../../attacks/domain/enums/medication_effect.dart';
import '../../../attacks/providers.dart';
import '../../domain/entities/attack_filter_options.dart';
import '../../domain/enums/attack_filters.dart';
import '../../domain/enums/history_period.dart';
import '../../domain/services/chart_analytics.dart';
import '../../providers.dart';

part 'history_filters_sheet_section.dart';

/// Every way the History list can be narrowed, in one sheet.
///
/// **One sheet rather than a chip per axis on the screen** (owner's call).
/// Twelve axes is more than a filter strip can hold, and a strip that scrolls
/// sideways hides exactly the filters nobody remembers they left on. Here the
/// whole state is one screenful, and the pill outside carries the count.
///
/// **Nothing is applied until the button is pressed.** The sheet works on a
/// draft, like every other picker in the app, and the button counts what the
/// draft would leave — so a filter that empties the list says so before it is
/// committed rather than after.
class HistoryFiltersSheet extends ConsumerStatefulWidget {
  const HistoryFiltersSheet({required this.initial, super.key});

  /// What is applied right now, so re-opening starts where the user left off.
  final AttackFilters initial;

  @override
  ConsumerState<HistoryFiltersSheet> createState() =>
      _HistoryFiltersSheetState();
}

class _HistoryFiltersSheetState extends ConsumerState<HistoryFiltersSheet> {
  late AttackFilters _draft = widget.initial;

  /// A period is one window: picking one replaces the last rather than adding to it.
  void _selectPeriod(HistoryPeriod period) =>
      setState(() => _draft = _draft.copyWith(period: period));

  /// The same value tapped twice comes back off — every other axis is a set, and a chip that could only be switched on would be a trap.
  Set<T> _toggle<T>(Set<T> values, T value) {
    final Set<T> next = <T>{...values};

    if (!next.remove(value)) next.add(value);

    return next;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AttackFilterOptions options = ref.watch(attackFilterOptionsProvider);
    // The count follows a sync landing while the sheet is open, not just the taps in it.
    ref.watch(attacksStreamProvider);
    final int matches = ref
        .read(attackFiltersProvider.notifier)
        .matchCount(_draft);

    return SdSheetContentV2(
      title: l10n.historyFiltersTitle,
      closeTooltip: l10n.commonClose,
      confirmLabel: l10n.historyFiltersApply(matches),
      // Committing an empty result is allowed: it is the honest answer to the filters, and the list says so where the user can undo it.
      onConfirm: () => Navigator.of(context).pop(_draft),
      // Only once something is on — a "reset" over an untouched sheet says nothing.
      footer: _draft.isDefault
          ? null
          : SdButtonV2(
              variant: SdButtonVariantV2.text,
              label: l10n.historyFiltersReset,
              // Clears the draft in place rather than closing: the button below it is still the one that writes.
              onPressed: () => setState(() => _draft = const AttackFilters()),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _FilterSection(
            title: l10n.historyFilterSectionPeriod,
            first: true,
            child: _ChipWrap<HistoryPeriod>(
              options: HistoryPeriod.values,
              isSelected: (HistoryPeriod value) => _draft.period == value,
              labelBuilder: (HistoryPeriod value) => value.label(l10n),
              onTap: _selectPeriod,
            ),
          ),
          _FilterSection(
            title: l10n.attackDetailIntensity,
            child: _ChipWrap<SeverityBand>(
              options: SeverityBand.values,
              isSelected: _draft.intensity.contains,
              labelBuilder: (SeverityBand value) => value.label(l10n),
              onTap: (SeverityBand value) => setState(() {
                _draft = _draft.copyWith(
                  intensity: _toggle(_draft.intensity, value),
                );
              }),
            ),
          ),
          _FilterSection(
            title: l10n.attackDetailDuration,
            child: _ChipWrap<AttackDurationBand>(
              options: AttackDurationBand.values,
              isSelected: _draft.duration.contains,
              labelBuilder: (AttackDurationBand value) => value.label(l10n),
              onTap: (AttackDurationBand value) => setState(() {
                _draft = _draft.copyWith(
                  duration: _toggle(_draft.duration, value),
                );
              }),
            ),
          ),
          _FilterSection(
            title: l10n.attackDetailAura,
            child: _ChipWrap<AuraFilterOption>(
              options: AuraFilterOption.values,
              isSelected: _draft.aura.contains,
              labelBuilder: (AuraFilterOption value) => value.label(l10n),
              onTap: (AuraFilterOption value) => setState(() {
                _draft = _draft.copyWith(aura: _toggle(_draft.aura, value));
              }),
            ),
          ),
          _FilterSection(
            title: l10n.attackDetailLocation,
            child: _ChipWrap<HeadRegion>(
              options: HeadRegion.values,
              isSelected: _draft.regions.contains,
              labelBuilder: (HeadRegion value) => value.label(l10n),
              onTap: (HeadRegion value) => setState(() {
                _draft = _draft.copyWith(regions: _toggle(_draft.regions, value));
              }),
            ),
          ),
          _FilterSection(
            title: l10n.attackDetailMedication,
            child: _ChipWrap<MedicationTakenFilter>(
              options: MedicationTakenFilter.values,
              isSelected: _draft.medication.contains,
              labelBuilder: (MedicationTakenFilter value) => value.label(l10n),
              onTap: (MedicationTakenFilter value) => setState(() {
                _draft = _draft.copyWith(
                  medication: _toggle(_draft.medication, value),
                );
              }),
            ),
          ),
          // The three free-text sections draw only what the user has actually recorded — a heading over no chips is a screen that looks broken.
          if (options.medicationNames.isNotEmpty)
            _FilterSection(
              title: l10n.historyFilterSectionMedicationName,
              child: _ChipWrap<String>(
                options: options.medicationNames,
                isSelected: _draft.medicationNames.contains,
                labelBuilder: (String value) => value,
                onTap: (String value) => setState(() {
                  _draft = _draft.copyWith(
                    medicationNames: _toggle(_draft.medicationNames, value),
                  );
                }),
              ),
            ),
          _FilterSection(
            title: l10n.attackDetailMedicationEffect,
            child: _ChipWrap<MedicationEffect>(
              options: MedicationEffect.values,
              isSelected: _draft.medicationEffects.contains,
              labelBuilder: (MedicationEffect value) => value.label(l10n),
              onTap: (MedicationEffect value) => setState(() {
                _draft = _draft.copyWith(
                  medicationEffects: _toggle(_draft.medicationEffects, value),
                );
              }),
            ),
          ),
          if (options.symptoms.isNotEmpty)
            _FilterSection(
              title: l10n.detailsSymptomsLabel,
              child: _ChipWrap<String>(
                options: options.symptoms,
                isSelected: _draft.symptoms.contains,
                labelBuilder: (String value) => value,
                onTap: (String value) => setState(() {
                  _draft = _draft.copyWith(
                    symptoms: _toggle(_draft.symptoms, value),
                  );
                }),
              ),
            ),
          if (options.triggers.isNotEmpty)
            _FilterSection(
              title: l10n.detailsTriggersLabel,
              child: _ChipWrap<String>(
                options: options.triggers,
                isSelected: _draft.triggers.contains,
                labelBuilder: (String value) => value,
                onTap: (String value) => setState(() {
                  _draft = _draft.copyWith(
                    triggers: _toggle(_draft.triggers, value),
                  );
                }),
              ),
            ),
          _FilterSection(
            title: l10n.detailsExertionLabel,
            child: _ChipWrap<ExertionLevel>(
              options: ExertionLevel.values,
              isSelected: _draft.exertion.contains,
              labelBuilder: (ExertionLevel value) => value.label(l10n),
              onTap: (ExertionLevel value) => setState(() {
                _draft = _draft.copyWith(
                  exertion: _toggle(_draft.exertion, value),
                );
              }),
            ),
          ),
          _FilterSection(
            title: l10n.detailsNotesLabel,
            child: _ChipWrap<NotesFilter>(
              options: NotesFilter.values,
              isSelected: _draft.notes.contains,
              labelBuilder: (NotesFilter value) => value.label(l10n),
              onTap: (NotesFilter value) => setState(() {
                _draft = _draft.copyWith(notes: _toggle(_draft.notes, value));
              }),
            ),
          ),
          _FilterSection(
            title: l10n.insightsPressureTitle,
            child: _ChipWrap<PressureTrendFilter>(
              options: PressureTrendFilter.values,
              isSelected: _draft.pressure.contains,
              labelBuilder: (PressureTrendFilter value) => value.label(l10n),
              onTap: (PressureTrendFilter value) => setState(() {
                _draft = _draft.copyWith(
                  pressure: _toggle(_draft.pressure, value),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension HistoryFiltersSheetExt on HistoryFiltersSheet {
  Future<AttackFilters?> show(BuildContext context) =>
      showSdBottomSheetV2<AttackFilters>(
        context,
        // Without it the route caps near half the screen and SdSheetContentV2's ceiling never applies.
        isScrollControlled: true,
        builder: (_) => this,
      );
}
