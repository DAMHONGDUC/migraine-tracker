/// The OS permissions the app asks for. New permissions are added here and
/// wired through [AppPermissionGateway] — features never touch the plugins
/// directly.
enum AppPermissionType { notification, location }

/// A permission's state, normalized across geolocator / flutter_local_
/// notifications. [permanentlyDenied] is the one that matters for UX: the OS
/// won't show its prompt again, so the only way back is the Settings app.
enum AppPermissionStatus { granted, denied, permanentlyDenied }
