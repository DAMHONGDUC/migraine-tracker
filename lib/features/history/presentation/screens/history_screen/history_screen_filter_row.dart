part of 'history_screen.dart';

/// One axis of the History filter: a chip showing the axis' name while it rests on "All", the picked value once there is one, and a single-choice sheet.
///
/// **The axis name is what tells thirteen chips apart.** Every axis defaults
/// to "All", so a strip of chips all resting would otherwise read "All" that
/// many times — the same rule the medications tab's three chips follow.
class _AxisChip<T> extends StatelessWidget {
  const _AxisChip({
    required this.axisName,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onSelected,
  });

  /// Localized name of the axis: "Intensity", "Aura", "Pressure".
  final String axisName;

  final T value;

  /// Every value the axis offers, **"All" first** — which is also how the chip knows it is resting, without being told twice.
  final List<T> options;

  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    // Resting on the first option IS "not filtered" — every axis puts its "all" there, so the chip needs telling neither which value that is nor whether it is on.
    final bool active = value != options.first;

    return SdFilterChipV2<T>(
      label: active ? labelBuilder(value) : axisName,
      selected: value,
      options: options,
      optionLabelBuilder: labelBuilder,
      onSelected: onSelected,
      sheetTitle: axisName,
      active: active,
    );
  }
}

/// One History filter axis, written once and drawn twice: as a chip in the strip and as a section of the all-filters sheet.
///
/// Callers hold a list of these typed `_Axis<Object?>`, so nothing outside
/// reads a field whose type mentions [T]; [chip] and [section] do it inside,
/// where [T] is the real one.
class _Axis<T> {
  const _Axis({
    required this.name,
    required this.options,
    required this.label,
    required this.read,
    required this.write,
    required this.commit,
  });

  /// Localized axis name: "Intensity", "Aura", "Pressure".
  final String name;

  /// **"All" first** — see [_AxisChip.options].
  final List<T> options;

  final String Function(T value) label;
  final T Function(AttackFilters filters) read;

  /// The filters with this axis set to a value — what the sheet's draft moves by.
  final AttackFilters Function(AttackFilters filters, T value) write;

  /// Sets this axis on the controller — what a chip's pick does, logged under the axis' own name.
  final void Function(AttackFiltersController controller, T value) commit;

  Widget chip(AttackFilters filters, AttackFiltersController controller) =>
      _AxisChip<T>(
        axisName: name,
        value: read(filters),
        options: options,
        labelBuilder: label,
        onSelected: (T value) => commit(controller, value),
      );

  Widget section(AttackFilters draft, ValueChanged<AttackFilters> onChanged) =>
      SdFilterSectionV2<T>(
        title: name,
        options: options,
        selected: read(draft),
        labelBuilder: label,
        onSelected: (T value) => onChanged(write(draft, value)),
      );
}

/// Every axis History filters on, in the order they are reached for — the one list both the strip and the sheet are built from.
final class _Axes {
  /// The values a free-text axis offers: "All" first, then the user's own words.
  static List<String> _textOptions(List<String> recorded) => <String>[
    AttackFilters.anyText,
    ...recorded,
  ];

  static List<_Axis<Object?>> of(
    AppLocalizations l10n,
    AttackFilterOptions options,
  ) {
    // An empty value is the "All" row; the user's own words label themselves.
    String text(String value) =>
        value == AttackFilters.anyText ? l10n.historyFilterAll : value;
    // A chip's value can be a tag id since the details sheet started writing them, and `nausea` is not a word this app shows anyone.
    String symptomText(String value) => value == AttackFilters.anyText
        ? l10n.historyFilterAll
        : value.symptomLabel(l10n);
    String triggerText(String value) => value == AttackFilters.anyText
        ? l10n.historyFilterAll
        : value.triggerLabel(l10n);

    return <_Axis<Object?>>[
      _Axis<HistoryPeriod>(
        name: l10n.historyFilterAxisPeriod,
        // "All" is last in `HistoryPeriod`, which every other axis puts first — reordered here so the resting value leads its own sheet.
        options: const <HistoryPeriod>[
          HistoryPeriod.all,
          HistoryPeriod.today,
          HistoryPeriod.week,
          HistoryPeriod.month,
          HistoryPeriod.year,
        ],
        label: (HistoryPeriod value) => value.label(l10n),
        read: (AttackFilters f) => f.period,
        write: (AttackFilters f, HistoryPeriod v) => f.copyWith(period: v),
        commit: (AttackFiltersController c, HistoryPeriod v) =>
            c.setPeriod(v),
      ),
      _Axis<IntensityFilter>(
        name: l10n.attackDetailIntensity,
        options: IntensityFilter.values,
        label: (IntensityFilter value) => value.label(l10n),
        read: (AttackFilters f) => f.intensity,
        write: (AttackFilters f, IntensityFilter v) =>
            f.copyWith(intensity: v),
        commit: (AttackFiltersController c, IntensityFilter v) =>
            c.setIntensity(v),
      ),
      _Axis<MedicationFilter>(
        name: l10n.attackDetailMedication,
        options: MedicationFilter.values,
        label: (MedicationFilter value) => value.label(l10n),
        read: (AttackFilters f) => f.medication,
        write: (AttackFilters f, MedicationFilter v) =>
            f.copyWith(medication: v),
        commit: (AttackFiltersController c, MedicationFilter v) =>
            c.setMedication(v),
      ),
      // The three free-text axes appear only once the user has written something into them — an axis offering only "All" says nothing.
      if (options.medicationNames.isNotEmpty)
        _Axis<String>(
          name: l10n.historyFilterAxisMedicationName,
          options: _textOptions(options.medicationNames),
          label: text,
          read: (AttackFilters f) => f.medicationName,
          write: (AttackFilters f, String v) => f.copyWith(medicationName: v),
          commit: (AttackFiltersController c, String v) =>
              c.setMedicationName(v),
        ),
      _Axis<EffectFilter>(
        name: l10n.attackDetailMedicationEffect,
        options: EffectFilter.values,
        label: (EffectFilter value) => value.label(l10n),
        read: (AttackFilters f) => f.effect,
        write: (AttackFilters f, EffectFilter v) => f.copyWith(effect: v),
        commit: (AttackFiltersController c, EffectFilter v) => c.setEffect(v),
      ),
      _Axis<AuraFilter>(
        name: l10n.attackDetailAura,
        options: AuraFilter.values,
        label: (AuraFilter value) => value.label(l10n),
        read: (AttackFilters f) => f.aura,
        write: (AttackFilters f, AuraFilter v) => f.copyWith(aura: v),
        commit: (AttackFiltersController c, AuraFilter v) => c.setAura(v),
      ),
      _Axis<AreaFilter>(
        name: l10n.attackDetailLocation,
        options: AreaFilter.values,
        label: (AreaFilter value) => value.label(l10n),
        read: (AttackFilters f) => f.area,
        write: (AttackFilters f, AreaFilter v) => f.copyWith(area: v),
        commit: (AttackFiltersController c, AreaFilter v) => c.setArea(v),
      ),
      _Axis<DurationFilter>(
        name: l10n.attackDetailDuration,
        options: DurationFilter.values,
        label: (DurationFilter value) => value.label(l10n),
        read: (AttackFilters f) => f.duration,
        write: (AttackFilters f, DurationFilter v) => f.copyWith(duration: v),
        commit: (AttackFiltersController c, DurationFilter v) =>
            c.setDuration(v),
      ),
      if (options.symptoms.isNotEmpty)
        _Axis<String>(
          name: l10n.detailsSymptomsLabel,
          options: _textOptions(options.symptoms),
          label: symptomText,
          read: (AttackFilters f) => f.symptom,
          write: (AttackFilters f, String v) => f.copyWith(symptom: v),
          commit: (AttackFiltersController c, String v) => c.setSymptom(v),
        ),
      if (options.triggers.isNotEmpty)
        _Axis<String>(
          name: l10n.detailsTriggersLabel,
          options: _textOptions(options.triggers),
          label: triggerText,
          read: (AttackFilters f) => f.trigger,
          write: (AttackFilters f, String v) => f.copyWith(trigger: v),
          commit: (AttackFiltersController c, String v) => c.setTrigger(v),
        ),
      _Axis<ExertionFilter>(
        name: l10n.detailsExertionLabel,
        options: ExertionFilter.values,
        label: (ExertionFilter value) => value.label(l10n),
        read: (AttackFilters f) => f.exertion,
        write: (AttackFilters f, ExertionFilter v) => f.copyWith(exertion: v),
        commit: (AttackFiltersController c, ExertionFilter v) =>
            c.setExertion(v),
      ),
      _Axis<NotesFilter>(
        name: l10n.detailsNotesLabel,
        options: NotesFilter.values,
        label: (NotesFilter value) => value.label(l10n),
        read: (AttackFilters f) => f.notes,
        write: (AttackFilters f, NotesFilter v) => f.copyWith(notes: v),
        commit: (AttackFiltersController c, NotesFilter v) => c.setNotes(v),
      ),
      _Axis<PressureFilter>(
        name: l10n.insightsPressureTitle,
        options: PressureFilter.values,
        label: (PressureFilter value) => value.label(l10n),
        read: (AttackFilters f) => f.pressure,
        write: (AttackFilters f, PressureFilter v) => f.copyWith(pressure: v),
        commit: (AttackFiltersController c, PressureFilter v) =>
            c.setPressure(v),
      ),
    ];
  }
}

/// The whole filter strip: the all-filters pill, then one chip per axis.
///
/// A bare [Row] on purpose — `SdCollapsingFilterScaffoldV2` supplies the
/// horizontal scrolling in both the strip and the app bar, so a scroll view
/// here would nest two.
class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  /// Gap between chips.
  static double get _gap => SdSpacingConstant.w8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AttackFilters filters = ref.watch(attackFiltersProvider);
    final AttackFiltersController controller = ref.read(
      attackFiltersProvider.notifier,
    );
    final List<_Axis<Object?>> axes = _Axes.of(
      context.l10n,
      ref.watch(attackFilterOptionsProvider),
    );

    return Row(
      children: <Widget>[
        AllFiltersPill(
          count: filters.activeCount,
          onTap: () async {
            final AttackFilters? picked = await _HistoryFilterSheet(
              initial: filters,
              axes: axes,
            ).show(context);
            if (!context.mounted) return;
            if (picked != null && picked != ref.read(attackFiltersProvider)) {
              controller.apply(picked);
            }
          },
        ),
        for (final _Axis<Object?> axis in axes) ...<Widget>[
          SizedBox(width: _gap),
          axis.chip(filters, controller),
        ],
      ],
    );
  }
}
