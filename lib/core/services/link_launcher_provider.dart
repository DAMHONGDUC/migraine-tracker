import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'link_launcher.dart';
import 'url_link_launcher.dart';

/// Opens external links — the paywall's Terms and Privacy, and the weather attribution Apple requires.
final linkLauncherProvider = Provider<LinkLauncher>(
  (ref) => const UrlLinkLauncher(),
);
