import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../domain/enums/attack_filters.dart';
import '../../domain/enums/history_period.dart';
import '../../domain/services/attack_filterer.dart';

/// The thirteen axes the History list is narrowed by, one chip each. Mirrors `MedicationFiltersController`'s role, which has three of them.
class AttackFiltersController extends Notifier<AttackFilters> {
  static const AttackFilterer _filterer = AttackFilterer();

  @override
  AttackFilters build() => const AttackFilters();

  void setPeriod(HistoryPeriod value) =>
      _set('period', value, state.copyWith(period: value));

  void setIntensity(IntensityFilter value) =>
      _set('intensity', value, state.copyWith(intensity: value));

  void setDuration(DurationFilter value) =>
      _set('duration', value, state.copyWith(duration: value));

  void setAura(AuraFilter value) =>
      _set('aura', value, state.copyWith(aura: value));

  void setArea(AreaFilter value) =>
      _set('area', value, state.copyWith(area: value));

  void setMedication(MedicationFilter value) =>
      _set('medication', value, state.copyWith(medication: value));

  void setMedicationName(String value) =>
      _set('medicationName', value, state.copyWith(medicationName: value));

  void setEffect(EffectFilter value) =>
      _set('effect', value, state.copyWith(effect: value));

  void setSymptom(String value) =>
      _set('symptom', value, state.copyWith(symptom: value));

  void setTrigger(String value) =>
      _set('trigger', value, state.copyWith(trigger: value));

  void setExertion(ExertionFilter value) =>
      _set('exertion', value, state.copyWith(exertion: value));

  void setNotes(NotesFilter value) =>
      _set('notes', value, state.copyWith(notes: value));

  void setPressure(PressureFilter value) =>
      _set('pressure', value, state.copyWith(pressure: value));

  /// Every axis at once, from the all-filters sheet's Apply.
  void apply(AttackFilters next) {
    SdLogger.action(
      LogTagConstant.history,
      'History filters applied',
      <String, Object>{'was': state.activeCount, 'now': next.activeCount},
    );
    state = next;
  }

  /// Every axis back to "all", from the summary line's own action.
  void reset() {
    SdLogger.action(
      LogTagConstant.history,
      'History filters reset',
      <String, Object>{'was': state.activeCount},
    );
    state = const AttackFilters();
  }

  /// Attacks matching every axis, newest first.
  List<Attack> filter(List<Attack> attacks) =>
      _filterer.apply(attacks, state, now: DateTime.now());

  /// One line per pick, naming the axis and what was picked — thirteen chips write here, so a console without the axis could not say which one moved.
  void _set(String axis, Object value, AttackFilters next) {
    SdLogger.action(LogTagConstant.history, 'History filter', <String, Object>{
      'axis': axis,
      'value': value is Enum ? value.name : value,
    });
    state = next;
  }
}
