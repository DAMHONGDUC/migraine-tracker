import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A pending "show me the alert row" request.
class PressureAlertHighlightController extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  /// Called by the row once it has scrolled to itself and lit up, so the next visit to the tab does not flash again unasked.
  void consume() => state = false;
}
