import 'head_region.dart';

/// The coarse head location the log flow used before [HeadRegion] replaced
/// it. **Legacy — nothing new should reach for this.** Two callers keep it
/// alive, and both are reading data written by an older build:
///  - the v12 → v13 database migration, and
///  - `AttackPayloadCodec`, decoding a sync payload another device pushed
///    before it updated.
///
/// A third caller *writes* it: `AttackPayloadCodec` still puts a coarse
/// `location` beside the new `regions` in every payload, so a second device
/// running the older build keeps reading this user's history instead of
/// throwing on every record. [coarsest] is what it writes.
///
/// [regions] is the mapping both readers use. It deliberately does **not**
/// invent precision: "left side" becomes every region on the left, not a guess at
/// which one of them hurt, so a migrated attack stays exactly as coarse as
/// the user actually said it was.
enum HeadLocation {
  left,
  right,
  front,
  back,
  whole;

  /// The nearest old value for a set of regions, for the legacy field the
  /// sync payload still carries. Lossy on purpose and in one direction only:
  /// anything that does not fall cleanly on one side, on the forehead, or on
  /// the back of the head reports as [whole], because an older build showing
  /// "whole head" is honest about not knowing where, while showing "left"
  /// for a right-sided attack would not be.
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
