import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/enums/insights_tab.dart';

/// Which of Insights' cards is showing.
///
/// A Notifier rather than local widget state: the screen rebuilds whenever a
/// correlation or a health read resolves, and a tab that snapped back to the
/// first one each time would read as a bug.
///
/// [InsightsTab.pressure] to start — the screen's own subject now that the
/// weather it used to open on lives on the dashboard.
class InsightsTabController extends Notifier<InsightsTab> {
  @override
  InsightsTab build() => InsightsTab.pressure;

  void set(InsightsTab tab) {
    SdLogger.action(LogTagConstant.insights, 'Insights tab', tab.name);
    state = tab;
  }
}
