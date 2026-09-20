import 'package:meta/meta.dart';

import '../enums/error_view_type.dart';

/// The `error_view` section of `app_config/current`: a notice the owner can
/// put in front of the whole app from the Firebase console.
///
/// **This entity existing *is* the switch.** `enable: false`, an absent
/// section, a malformed one, or one with nothing to say parse to null rather
/// than to an instance with a flag — the same shape `AppConfig.forceUpdate`
/// uses, and it keeps "should this show" from being asked in two places that
/// could one day disagree.
///
/// **The copy is the owner's and is not localized.** Every other string in the
/// app goes through the ARB files; these three are typed into the console when
/// something is wrong, in whatever language the owner writes, and there is no
/// key to translate ahead of an incident nobody has had yet.
@immutable
class ErrorViewConfig {
  const ErrorViewConfig({
    required this.title,
    required this.type,
    this.subtitle1 = '',
    this.subtitle2 = '',
  });

  /// The headline. **Never empty** — a notice with no title is one the mapper
  /// drops, because a blank screen tells the user less than the app did.
  final String title;

  /// The first body line, and the second. Either may be empty; the view draws
  /// only the ones that carry text, so the owner can say one thing or three.
  final String subtitle1;
  final String subtitle2;

  /// The glyph and its colour. See [ErrorViewType].
  final ErrorViewType type;

  /// Value equality, for the same reason `AppConfig` has it: this rides on a
  /// Firestore stream that re-emits on metadata alone, and without it the gate
  /// rebuilds when nothing it reads has changed.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorViewConfig &&
          other.title == title &&
          other.subtitle1 == subtitle1 &&
          other.subtitle2 == subtitle2 &&
          other.type == type;

  @override
  int get hashCode => Object.hash(title, subtitle1, subtitle2, type);
}
