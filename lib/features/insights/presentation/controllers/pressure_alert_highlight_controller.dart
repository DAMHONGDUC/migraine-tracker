import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A pending "show me the alert row" request.
///
/// The shortcuts that mean *alerts* — the dashboard tile, the Settings row,
/// the alert notification — all land on the pressure card, where the switch
/// is the last thing on it and usually below the fold. Arriving at a card the
/// user then has to search is barely better than not arriving, so the request
/// travels with the navigation and the row scrolls itself into view.
///
/// **A flag the widget consumes, not an event it might miss.** The card is
/// built *after* the move, so a listener would be subscribing to something
/// already fired; leaving it set until the row has handled it is what makes
/// the order not matter.
class PressureAlertHighlightController extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  /// Called by the row once it has scrolled to itself and lit up, so the
  /// next visit to the tab does not flash again unasked.
  void consume() => state = false;
}
