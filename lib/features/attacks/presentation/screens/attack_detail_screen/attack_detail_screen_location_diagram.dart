part of 'attack_detail_screen.dart';

/// Read-only head diagram highlighting where this attack's pain was —
/// the same [HeadDiagram] used to pick the location in the 3-tap log flow.
class _LocationDiagram extends StatelessWidget {
  const _LocationDiagram({required this.location});

  final HeadLocation location;

  @override
  Widget build(BuildContext context) {
    return _Section(
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacingConstant.w16),
          child: SizedBox(
            height: AppSpacingConstant.h160,
            child: HeadDiagram(selected: location),
          ),
        ),
      ],
    );
  }
}
