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

/// The whole filter strip: one chip per axis, in the order they are reached for.
///
/// A bare [Row] on purpose — `SdCollapsingFilterScaffoldV2` supplies the
/// horizontal scrolling in both the strip and the app bar, so a scroll view
/// here would nest two.
class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  /// Gap between chips.
  static double get _gap => SdSpacingConstant.w8;

  /// The values a free-text axis offers: "All" first, then the user's own words.
  static List<String> _textOptions(List<String> recorded) => <String>[
    AttackFilters.anyText,
    ...recorded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AttackFilters filters = ref.watch(attackFiltersProvider);
    final AttackFiltersController controller = ref.read(
      attackFiltersProvider.notifier,
    );
    final AttackFilterOptions options = ref.watch(attackFilterOptionsProvider);
    // An empty value is the "All" row; the user's own words label themselves.
    String text(String value) =>
        value == AttackFilters.anyText ? l10n.historyFilterAll : value;

    return Row(
      children: <Widget>[
        _AxisChip<HistoryPeriod>(
          axisName: l10n.historyFilterAxisPeriod,
          value: filters.period,
          // "All" is last in `HistoryPeriod`, which every other axis puts first — reordered here so the chip's resting value leads its own sheet.
          options: const <HistoryPeriod>[
            HistoryPeriod.all,
            HistoryPeriod.today,
            HistoryPeriod.week,
            HistoryPeriod.month,
            HistoryPeriod.year,
          ],
          labelBuilder: (HistoryPeriod value) => value.label(l10n),
          onSelected: controller.setPeriod,
        ),
        SizedBox(width: _gap),
        _AxisChip<IntensityFilter>(
          axisName: l10n.attackDetailIntensity,
          value: filters.intensity,
          options: IntensityFilter.values,
          labelBuilder: (IntensityFilter value) => value.label(l10n),
          onSelected: controller.setIntensity,
        ),
        SizedBox(width: _gap),
        _AxisChip<MedicationFilter>(
          axisName: l10n.attackDetailMedication,
          value: filters.medication,
          options: MedicationFilter.values,
          labelBuilder: (MedicationFilter value) => value.label(l10n),
          onSelected: controller.setMedication,
        ),
        // The three free-text axes appear only once the user has written something into them — a chip whose sheet holds one row says nothing.
        if (options.medicationNames.isNotEmpty) ...<Widget>[
          SizedBox(width: _gap),
          _AxisChip<String>(
            axisName: l10n.historyFilterAxisMedicationName,
            value: filters.medicationName,
            options: _textOptions(options.medicationNames),
            labelBuilder: text,
            onSelected: controller.setMedicationName,
          ),
        ],
        SizedBox(width: _gap),
        _AxisChip<EffectFilter>(
          axisName: l10n.attackDetailMedicationEffect,
          value: filters.effect,
          options: EffectFilter.values,
          labelBuilder: (EffectFilter value) => value.label(l10n),
          onSelected: controller.setEffect,
        ),
        SizedBox(width: _gap),
        _AxisChip<AuraFilter>(
          axisName: l10n.attackDetailAura,
          value: filters.aura,
          options: AuraFilter.values,
          labelBuilder: (AuraFilter value) => value.label(l10n),
          onSelected: controller.setAura,
        ),
        SizedBox(width: _gap),
        _AxisChip<AreaFilter>(
          axisName: l10n.attackDetailLocation,
          value: filters.area,
          options: AreaFilter.values,
          labelBuilder: (AreaFilter value) => value.label(l10n),
          onSelected: controller.setArea,
        ),
        SizedBox(width: _gap),
        _AxisChip<DurationFilter>(
          axisName: l10n.attackDetailDuration,
          value: filters.duration,
          options: DurationFilter.values,
          labelBuilder: (DurationFilter value) => value.label(l10n),
          onSelected: controller.setDuration,
        ),
        if (options.symptoms.isNotEmpty) ...<Widget>[
          SizedBox(width: _gap),
          _AxisChip<String>(
            axisName: l10n.detailsSymptomsLabel,
            value: filters.symptom,
            options: _textOptions(options.symptoms),
            labelBuilder: text,
            onSelected: controller.setSymptom,
          ),
        ],
        if (options.triggers.isNotEmpty) ...<Widget>[
          SizedBox(width: _gap),
          _AxisChip<String>(
            axisName: l10n.detailsTriggersLabel,
            value: filters.trigger,
            options: _textOptions(options.triggers),
            labelBuilder: text,
            onSelected: controller.setTrigger,
          ),
        ],
        SizedBox(width: _gap),
        _AxisChip<ExertionFilter>(
          axisName: l10n.detailsExertionLabel,
          value: filters.exertion,
          options: ExertionFilter.values,
          labelBuilder: (ExertionFilter value) => value.label(l10n),
          onSelected: controller.setExertion,
        ),
        SizedBox(width: _gap),
        _AxisChip<NotesFilter>(
          axisName: l10n.detailsNotesLabel,
          value: filters.notes,
          options: NotesFilter.values,
          labelBuilder: (NotesFilter value) => value.label(l10n),
          onSelected: controller.setNotes,
        ),
        SizedBox(width: _gap),
        _AxisChip<PressureFilter>(
          axisName: l10n.insightsPressureTitle,
          value: filters.pressure,
          options: PressureFilter.values,
          labelBuilder: (PressureFilter value) => value.label(l10n),
          onSelected: controller.setPressure,
        ),
      ],
    );
  }
}
