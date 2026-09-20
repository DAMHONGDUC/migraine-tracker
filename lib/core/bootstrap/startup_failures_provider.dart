import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The startup steps that threw, by step name, each holding what it threw.
///
/// The error itself rather than its text: `StartupErrorGate` decides on the
/// *type* of the failure, and a step's name says only where it happened — the
/// Firebase step fails both when the build points at the wrong project and
/// when there is no backend to reach, and only one of those is a broken build.
///
/// Filled in `main` from what `SdBootstrap` reports and handed to the tree as
/// an override, because the failures happen before there is a tree to put them
/// in. Empty by default, which is what a widget test and any second entry
/// point get — a screen reading this must treat empty as "nothing failed",
/// never as "not asked yet".
final Provider<Map<String, Object>> startupFailuresProvider =
    Provider<Map<String, Object>>((Ref ref) => const <String, Object>{});
