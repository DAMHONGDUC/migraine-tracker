import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app_permission_gateway.dart';
import 'app_permission_types.dart';
import 'widgets/permission_settings_sheet.dart';

export 'app_permission_types.dart';

/// One entry point for every OS permission the app needs. A feature that needs
/// a permission calls [ensure]: it requests, and if the OS won't prompt again
/// (permanently denied) it shows a bottom sheet explaining why and offering a
/// jump to Settings. Platform calls live in [AppPermissionGateway]; this class
/// owns the flow + the settings-redirect UX.
class AppPermission {
  const AppPermission(this._gateway);

  final AppPermissionGateway _gateway;

  Future<AppPermissionStatus> status(AppPermissionType type) =>
      _gateway.status(type);

  /// Requests [type]. Returns true only when granted. On a permanent denial,
  /// shows the settings sheet (needs a live [context] to present it) and
  /// returns false. On a normal denial, returns false without a sheet — the
  /// caller can quietly proceed without the feature.
  Future<bool> ensure(BuildContext context, AppPermissionType type) async {
    final status = await _gateway.request(type);
    if (status == AppPermissionStatus.granted) return true;
    if (status == AppPermissionStatus.permanentlyDenied && context.mounted) {
      await showPermissionSettingsSheet(
        context,
        type: type,
        onOpenSettings: _gateway.openAppSettings,
      );
    }
    return false;
  }

  Future<void> openAppSettings() => _gateway.openAppSettings();
}

/// The platform gateway — overridden with a fake in tests.
final appPermissionGatewayProvider = Provider<AppPermissionGateway>(
  (ref) => PlatformPermissionGateway(),
);

/// The app-wide permission handler. Read it wherever a feature needs a
/// permission: `await ref.read(appPermissionProvider).ensure(context, type)`.
final appPermissionProvider = Provider<AppPermission>(
  (ref) => AppPermission(ref.watch(appPermissionGatewayProvider)),
);
