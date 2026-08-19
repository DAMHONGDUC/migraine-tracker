import '../../features/attacks/domain/enums/head_region.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shared user-facing labels for [HeadRegion]; used by the log flow, history
/// and the doctor report so features don't import each other's presentation
/// layer.
///
/// Left and right are the *user's own*, not the screen's — the front view of
/// the diagram is mirrored so the two agree (see [HeadRegion]).
extension HeadRegionLabel on HeadRegion {
  String label(AppLocalizations l10n) => switch (this) {
    HeadRegion.crown => l10n.regionCrown,
    HeadRegion.foreheadL => l10n.regionForeheadL,
    HeadRegion.foreheadR => l10n.regionForeheadR,
    HeadRegion.templeL => l10n.regionTempleL,
    HeadRegion.templeR => l10n.regionTempleR,
    HeadRegion.eyeL => l10n.regionEyeL,
    HeadRegion.eyeR => l10n.regionEyeR,
    HeadRegion.nose => l10n.regionNose,
    HeadRegion.cheekL => l10n.regionCheekL,
    HeadRegion.cheekR => l10n.regionCheekR,
    HeadRegion.jawL => l10n.regionJawL,
    HeadRegion.jawR => l10n.regionJawR,
    HeadRegion.occipitalL => l10n.regionOccipitalL,
    HeadRegion.occipitalR => l10n.regionOccipitalR,
    HeadRegion.nape => l10n.regionNape,
  };
}

/// The one way an attack's areas are spelled out in a sentence — the detail
/// screen, the history row and the PDF's table cell all read the same.
extension HeadRegionListLabel on List<HeadRegion> {
  String label(AppLocalizations l10n) =>
      map((HeadRegion r) => r.label(l10n)).join(', ');
}
