import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';
import '../../domain/enums/attack_filters.dart';
import '../../domain/enums/history_period.dart';
import '../../domain/services/attack_filterer.dart';

/// Every axis the History list is narrowed by. One sheet writes the whole value, so this takes an [AttackFilters] rather than carrying a setter per axis.
class AttackFiltersController extends Notifier<AttackFilters> {
  static const AttackFilterer _filterer = AttackFilterer();

  @override
  AttackFilters build() => const AttackFilters();

  /// Applies what the sheet collected.
  void apply(AttackFilters filters) {
    SdLogger.action(
      LogTagConstant.history,
      'History filters',
      _payload(filters),
    );
    state = filters;
  }

  /// Back to showing everything, from the sheet's own Reset.
  void reset() {
    SdLogger.action(LogTagConstant.history, 'History filters reset', _payload(state));
    state = const AttackFilters();
  }

  /// Attacks matching [filters] — the applied ones, or a [draft] the sheet is still collecting, which is how its button counts before anything is committed.
  List<Attack> filter(List<Attack> attacks, {AttackFilters? draft}) =>
      _filterer.apply(attacks, draft ?? state, now: DateTime.now());

  /// How many attacks a draft would leave, for the sheet's confirm button.
  int matchCount(AttackFilters draft) => filter(
    ref.read(attacksStreamProvider).value ?? const <Attack>[],
    draft: draft,
  ).length;

  /// What a log line carries: the period, how many axes are on, and the values of only the axes that are — the full twelve would bury the two that changed.
  Map<String, Object> _payload(AttackFilters filters) {
    final Map<String, Object> data = <String, Object>{
      'activeAxes': filters.activeCount,
    };

    if (filters.period != HistoryPeriod.all) data['period'] = filters.period.name;
    _add(data, 'intensity', filters.intensity);
    _add(data, 'duration', filters.duration);
    _add(data, 'aura', filters.aura);
    _add(data, 'regions', filters.regions);
    _add(data, 'medication', filters.medication);
    _add(data, 'medicationNames', filters.medicationNames);
    _add(data, 'medicationEffects', filters.medicationEffects);
    _add(data, 'symptoms', filters.symptoms);
    _add(data, 'triggers', filters.triggers);
    _add(data, 'exertion', filters.exertion);
    _add(data, 'notes', filters.notes);
    _add(data, 'pressure', filters.pressure);

    return data;
  }

  /// Names one axis' picked values, enums by their `name` and free text as written, and says nothing at all when the axis is off.
  void _add(Map<String, Object> data, String key, Set<Object> values) {
    if (values.isEmpty) return;

    data[key] = values
        .map((Object value) => value is Enum ? value.name : value.toString())
        .toList();
  }
}
