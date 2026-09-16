import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The startup steps that threw, by step name, each holding what it threw.
///
/// Filled in `main` from what `SdBootstrap` reports and handed to the tree as
/// an override, because the failures happen before there is a tree to put them
/// in. Empty by default, which is what a widget test and any second entry
/// point get — a screen reading this must treat empty as "nothing failed",
/// never as "not asked yet".
final Provider<Map<String, String>> startupFailuresProvider =
    Provider<Map<String, String>>((Ref ref) => const <String, String>{});
