import 'package:permission_handler/permission_handler.dart' as ph;

import 'app_permission_types.dart';

/// The platform side of [AppPermission] — behind an interface so the
/// orchestration (and its settings-redirect UX) is testable with a fake
/// instead of the real OS.
abstract interface class AppPermissionGateway {
  Future<AppPermissionStatus> status(AppPermissionType type);

  /// Requests [type], prompting the OS dialog when it still can. Returns the
  /// resulting status ([AppPermissionStatus.permanentlyDenied] when the dialog
  /// can no longer be shown).
  Future<AppPermissionStatus> request(AppPermissionType type);

  /// Opens the OS app-settings page — the only way back from a permanent
  /// denial.
  Future<void> openAppSettings();
}

/// Real gateway, backed by the `permission_handler` package so every
/// permission goes through one uniform API (rather than each plugin's own).
class PlatformPermissionGateway implements AppPermissionGateway {
  const PlatformPermissionGateway();

  ph.Permission _permission(AppPermissionType type) => switch (type) {
    AppPermissionType.notification => ph.Permission.notification,
    // Hard rule: While-Using only, never Always.
    AppPermissionType.location => ph.Permission.locationWhenInUse,
  };

  @override
  Future<AppPermissionStatus> status(AppPermissionType type) async =>
      _map(await _permission(type).status);

  @override
  Future<AppPermissionStatus> request(AppPermissionType type) async =>
      _map(await _permission(type).request());

  @override
  Future<void> openAppSettings() => ph.openAppSettings();

  AppPermissionStatus _map(ph.PermissionStatus status) => switch (status) {
    ph.PermissionStatus.granted ||
    ph.PermissionStatus.limited ||
    ph.PermissionStatus.provisional => AppPermissionStatus.granted,
    ph.PermissionStatus.denied => AppPermissionStatus.denied,
    // Restricted (parental controls etc.) is also unrecoverable in-app.
    ph.PermissionStatus.permanentlyDenied ||
    ph.PermissionStatus.restricted => AppPermissionStatus.permanentlyDenied,
  };
}
