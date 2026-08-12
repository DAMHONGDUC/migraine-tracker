import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/enums/insights_tab.dart';

/// Which of Insights' cards is showing.
///
/// A Notifier rather than local widget state, for the same reason the weather
/// card's own controls are: the screen rebuilds whenever a correlation or a
/// health read resolves, and a tab that snapped back to Weather each time
/// would read as a bug.
///
/// [InsightsTab.weather] to start — the one card every user has something on,
/// signed in or out, premium or not.
class InsightsTabController extends Notifier<InsightsTab> {
  @override
  InsightsTab build() => InsightsTab.weather;

  void set(InsightsTab tab) {
    AppLogger.action('Insights tab', tab.name);
    state = tab;
  }
}
