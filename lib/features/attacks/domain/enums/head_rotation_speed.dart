/// How far the head turns per point of drag, as a share of the full speed.
///
/// **A ladder of three, not a slider** (owner's rule, 2026-09-19, asking for a
/// way to make the turn less sensitive). The control sits over the head as one
/// button, and a button can cycle named steps where it cannot hold a
/// continuous value — and the answer being one of three is also what lets it
/// be printed back ("50%") instead of felt for.
///
/// The factor multiplies `HeadViewportUtils.degreesPerPoint`, so the gesture
/// keeps one owner for how fast a drag turns anything.
enum HeadRotationSpeed {
  slow(0.5),
  reduced(0.75),
  full(1);

  const HeadRotationSpeed(this.factor);

  final double factor;

  /// What the button prints and what the store keeps — an int, because a
  /// stored `0.5` read back as `0.5000000001` would match no step.
  int get percent => (factor * 100).round();

  /// Where a head that has never been slowed down turns.
  static const HeadRotationSpeed initial = full;

  /// The next step DOWN, wrapping to [full] at the bottom.
  ///
  /// One direction on purpose: the control was asked for as "make it less
  /// sensitive", so every press reduces and the wrap is the way back. Two
  /// buttons would have cost the row a target to undo what one press does.
  HeadRotationSpeed get slower => switch (this) {
    full => reduced,
    reduced => slow,
    slow => full,
  };

  /// A stored [percent] read back, or [initial] for anything this ladder has
  /// no step for — an older build's value, or a half-written one.
  static HeadRotationSpeed fromPercent(int? percent) => values.firstWhere(
    (HeadRotationSpeed speed) => speed.percent == percent,
    orElse: () => initial,
  );
}
