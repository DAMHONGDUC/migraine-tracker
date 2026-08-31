import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/enums/history_view_mode.dart';

/// List ↔ calendar ↔ chart toggle on the History app bar.
///
/// The period filter used to live here beside it; it is one axis of
/// [AttackFilters] now, held by `AttackFiltersController`, because a screen
/// with twelve axes and one sheet cannot have one of them stored somewhere
/// else.
class HistoryViewModeController extends Notifier<HistoryViewMode> {
  @override
  HistoryViewMode build() => HistoryViewMode.list;

  void select(HistoryViewMode mode) {
    SdLogger.action(LogTagConstant.history, 'History view', mode.name);
    state = mode;
  }
}
