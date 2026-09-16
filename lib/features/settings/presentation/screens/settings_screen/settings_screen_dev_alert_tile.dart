part of 'settings_screen.dart';

/// Dev-only: fires the in-app alert, so its look and its swipe can be checked
/// without provoking the thing that would normally raise one.
///
/// Every tap fires the *next* combination rather than the same one twice: six
/// taps walk the three kinds across both edges, which is what makes the
/// swipe-to-dismiss direction — up at the top, down at the bottom — testable
/// from one row.
class _DevAlertTile extends StatefulWidget {
  const _DevAlertTile();

  /// In the order the row walks them.
  static const List<SdSnackBarKindV2> kinds = <SdSnackBarKindV2>[
    SdSnackBarKindV2.success,
    SdSnackBarKindV2.error,
    SdSnackBarKindV2.info,
  ];

  @override
  State<_DevAlertTile> createState() => _DevAlertTileState();
}

class _DevAlertTileState extends State<_DevAlertTile> {
  /// Taps so far. Kind is this modulo three and placement is its parity, so
  /// the two cycles only realign every sixth tap — one per combination.
  int _fired = 0;

  void _fire() {
    final SdSnackBarKindV2 kind =
        _DevAlertTile.kinds[_fired % _DevAlertTile.kinds.length];
    final SdSnackBarPlacementV2 placement = _fired.isEven
        ? SdSnackBarPlacementV2.bottom
        : SdSnackBarPlacementV2.top;

    SdLogger.action(LogTagConstant.devAlert, 'Fire test alert', <String, Object>{
      'kind': kind.name,
      'placement': placement.name,
      'fired': _fired,
    });

    final String message = context.l10n.settingsDevAlertMessage;

    switch (kind) {
      case SdSnackBarKindV2.success:
        SdSnackBarUtilsV2.success(context, message, placement: placement);
      case SdSnackBarKindV2.error:
        SdSnackBarUtilsV2.error(context, message, placement: placement);
      case SdSnackBarKindV2.info:
        SdSnackBarUtilsV2.info(context, message, placement: placement);
    }

    setState(() => _fired++);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: AppIconConstant.info,
      iconColor: context.colorScheme.primary,
      title: context.l10n.settingsDevAlert,
      onTap: _fire,
    );
  }
}
