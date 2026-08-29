import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../widgets/permission_settings_sheet.dart';
import 'app_permission_gateway.dart';
import 'app_permission_types.dart';

export 'app_permission_types.dart';

/// One entry point for every OS permission the app needs.
class AppPermission {
  const AppPermission(this._gateway);

  final AppPermissionGateway _gateway;

  Future<AppPermissionStatus> status(AppPermissionType type) =>
      _gateway.status(type);

  /// Prompts, and says only whether it was granted.
  Future<bool> request(AppPermissionType type) async =>
      await _gateway.request(type) == AppPermissionStatus.granted;

  /// Requests [type].
  Future<bool> ensure(BuildContext context, AppPermissionType type) async {
    final status = await _gateway.request(type);
    if (status == AppPermissionStatus.granted) return true;
    if (status == AppPermissionStatus.permanentlyDenied && context.mounted) {
      await PermissionSettingsSheet(
        type: type,
        onOpenSettings: _gateway.openAppSettings,
      ).show(context);
    }
    return false;
  }

  Future<void> openAppSettings() => _gateway.openAppSettings();
}

/// The platform gateway — overridden with a fake in tests.
final appPermissionGatewayProvider = Provider<AppPermissionGateway>(
  (ref) => PlatformPermissionGateway(),
);

/// The app-wide permission handler. Read it wherever a feature needs a permission: `await ref.read(appPermissionProvider).ensure(context, type)`.
final appPermissionProvider = Provider<AppPermission>(
  (ref) => AppPermission(ref.watch(appPermissionGatewayProvider)),
);
