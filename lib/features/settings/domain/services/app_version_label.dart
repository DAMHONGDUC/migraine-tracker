import '../../../../core/env/app_env.dart';
import '../../../app_update/domain/entities/installed_app_version.dart';

/// "dev - 1.4.0 - 12" — env, marketing version and build number, in the one
/// format the About row and the support email body both use.
final class AppVersionLabel {
  const AppVersionLabel._();

  static String build(InstalledAppVersion? version) => version == null
      ? AppEnv.flavor
      : '${AppEnv.flavor} - ${version.buildName} (${version.buildNumber})';
}
