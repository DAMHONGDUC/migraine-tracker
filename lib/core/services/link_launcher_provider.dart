import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'link_launcher.dart';
import 'url_link_launcher.dart';

/// Opens external links — the paywall's Terms and Privacy, and the weather
/// attribution Apple requires.
///
/// In `core/` rather than a feature's `providers.dart` because two unrelated
/// features now want it, and the second would otherwise be importing the
/// first's wiring for something neither of them owns.
///
/// Widget tests override it; without that, tapping a link reaches the
/// url_launcher plugin.
final linkLauncherProvider = Provider<LinkLauncher>(
  (ref) => const UrlLinkLauncher(),
);
