import '../entities/attack.dart';

/// The free plan's readable window, as a pure function.
///
/// It is a function rather than a provider on purpose. The window depends on
/// the entitlement, and a widely watched PROVIDER that does gets torn down and
/// rebuilt the moment premium flips — which, mid route transition, Riverpod
/// reports as "setState called during build". A widget watching
/// `freeHistoryStartProvider` and calling this rebuilds the way any widget
/// does, and the provider graph never churns.
final class AttackWindow {
  const AttackWindow._();

  /// [attacks] minus everything older than [from]; the whole list when [from] is null (premium).
  static List<Attack> within(List<Attack> attacks, DateTime? from) {
    if (from == null) return attacks;

    final DateTime cutoff = from.toUtc();

    return attacks
        .where((Attack attack) => !attack.startedAt.isBefore(cutoff))
        .toList();
  }

  /// Whether [attack] sits behind the window — shown, but not readable.
  ///
  /// **The window marks a row now, it does not remove it** (owner's rule,
  /// 2026-09-21). History draws every attack and blurs the ones this answers
  /// true for; [within] stays because the charts and the filter options still
  /// read the readable set, and a chart averaging numbers the user cannot see
  /// is a number they cannot check.
  static bool locks(Attack attack, DateTime? from) =>
      from != null && attack.startedAt.isBefore(from.toUtc());

  /// Whether anything at all sits behind the window.
  static bool hides(List<Attack> attacks, DateTime? from) {
    if (from == null) return false;

    final DateTime cutoff = from.toUtc();

    return attacks.any((Attack attack) => attack.startedAt.isBefore(cutoff));
  }
}
