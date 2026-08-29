/// Which way the head diagram is facing.
enum HeadView { front, back }

/// One tappable area of the head — second tap of the 3-tap log, which now takes a *set* of these rather than one coarse [HeadLocation].
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

  /// The regions drawn on [view], in enum order — which is top-to-bottom, so a list of them reads down the head.
  static List<HeadRegion> of(HeadView view) => <HeadRegion>[
    for (final HeadRegion region in values)
      if (region.showsOn(view)) region,
  ];

  /// The view to open on for a saved attack: whichever holds more of its regions, front on a tie.
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
