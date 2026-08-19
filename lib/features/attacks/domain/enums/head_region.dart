/// Which way the head diagram is facing.
enum HeadView { front, back }

/// One tappable area of the head — second tap of the 3-tap log, which now
/// takes a *set* of these rather than one coarse [HeadLocation].
///
/// **Screen-left is always the user's own left.** The front view is drawn as
/// a mirror, the way the user sees themselves in one, so the side they tap is
/// the side that hurts. Anatomically a front view would put their left on the
/// screen's right — but nobody tapping "where does it hurt" thinks that way,
/// and a mirrored diagram is what keeps `templeL` meaning the left temple in
/// the doctor report. The back view needs no mirroring: standing behind
/// someone, their left is already on your left.
///
/// [crown] is the only region on both views, because the top of the head is
/// one place however you look at it.
///
/// [nose] is the only region with no side, and the only one that is not a
/// slab: it is the nose's own outline, cut out of [eyeL]/[eyeR] and
/// [cheekL]/[cheekR]. It sits ON the midline rather than either part of it,
/// so it is one area and never an L and an R — the nose and the sinus behind
/// it are one place to a user pointing at where it hurts (owner's call,
/// after a first pass that split them at the under-eye line). It belongs to
/// no [HeadLocation] for the same reason: the legacy coarse field has no
/// word for the middle, and "left" would be a lie.
enum HeadRegion {
  crown(<HeadView>{HeadView.front, HeadView.back}),
  foreheadL(<HeadView>{HeadView.front}),
  foreheadR(<HeadView>{HeadView.front}),
  templeL(<HeadView>{HeadView.front}),
  templeR(<HeadView>{HeadView.front}),
  eyeL(<HeadView>{HeadView.front}),
  nose(<HeadView>{HeadView.front}),
  eyeR(<HeadView>{HeadView.front}),
  cheekL(<HeadView>{HeadView.front}),
  cheekR(<HeadView>{HeadView.front}),
  jawL(<HeadView>{HeadView.front}),
  jawR(<HeadView>{HeadView.front}),
  occipitalL(<HeadView>{HeadView.back}),
  occipitalR(<HeadView>{HeadView.back}),
  nape(<HeadView>{HeadView.back});

  const HeadRegion(this.views);

  /// Every view this region is drawn on. Only [crown] has two.
  final Set<HeadView> views;

  bool showsOn(HeadView view) => views.contains(view);

  /// The regions drawn on [view], in enum order — which is top-to-bottom, so
  /// a list of them reads down the head.
  static List<HeadRegion> of(HeadView view) => <HeadRegion>[
    for (final HeadRegion region in values)
      if (region.showsOn(view)) region,
  ];

  /// The view to open on for a saved attack: whichever holds more of its
  /// regions, front on a tie. An attack logged as "back of head" must not
  /// open on a front view with nothing highlighted.
  static HeadView primaryView(List<HeadRegion> regions) {
    int front = 0;
    int back = 0;

    for (final HeadRegion region in regions) {
      if (region.showsOn(HeadView.front)) front++;
      if (region.showsOn(HeadView.back)) back++;
    }

    return back > front ? HeadView.back : HeadView.front;
  }
}
