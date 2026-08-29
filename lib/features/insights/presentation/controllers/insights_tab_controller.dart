import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/enums/insights_tab.dart';

/// Which of Insights' cards is showing.
class InsightsTabController extends Notifier<InsightsTab> {
  @override
  InsightsTab build() => InsightsTab.pressure;

  void set(InsightsTab tab) {
    SdLogger.action(LogTagConstant.insights, 'Insights tab', tab.name);
    state = tab;
  }
}
