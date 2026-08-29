import 'head_region.dart';

/// The coarse head location the log flow used before [HeadRegion] replaced it.
enum HeadLocation {
  left,
  right,
  front,
  back,
  whole;

  /// The nearest old value for a set of regions, for the legacy field the sync payload still carries.
  static HeadLocation coarsest(List<HeadRegion> regions) {
    if (regions.isEmpty) return whole;

    bool everyOneIn(HeadLocation location) =>
        regions.every(location.regions.contains);

    for (final HeadLocation candidate in <HeadLocation>[
      front,
      back,
      left,
      right,
    ]) {
      if (everyOneIn(candidate)) return candidate;
    }

    return whole;
  }
}

extension HeadLocationRegions on HeadLocation {
  List<HeadRegion> get regions => switch (this) {
    HeadLocation.left => const <HeadRegion>[
      HeadRegion.foreheadL,
      HeadRegion.templeL,
      HeadRegion.eyeL,
      HeadRegion.cheekL,
      HeadRegion.jawL,
      HeadRegion.occipitalL,
    ],
    HeadLocation.right => const <HeadRegion>[
      HeadRegion.foreheadR,
      HeadRegion.templeR,
      HeadRegion.eyeR,
      HeadRegion.cheekR,
      HeadRegion.jawR,
      HeadRegion.occipitalR,
    ],
    HeadLocation.front => const <HeadRegion>[
      HeadRegion.foreheadL,
      HeadRegion.foreheadR,
    ],
    HeadLocation.back => const <HeadRegion>[
      HeadRegion.occipitalL,
      HeadRegion.occipitalR,
      HeadRegion.nape,
    ],
    HeadLocation.whole => HeadRegion.values,
  };
}
