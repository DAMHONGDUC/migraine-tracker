import '../../domain/entities/error_view_config.dart';
import '../../domain/enums/error_view_type.dart';

/// The `error_view` section of `app_config/current`, in one place. The
/// collection and document names belong to `AppConfigSchema`, which owns every
/// name on the document.
abstract final class ErrorViewMapper {
  static const String enableField = 'enable';
  static const String titleField = 'title';
  static const String subtitle1Field = 'subtitle_1';
  static const String subtitle2Field = 'subtitle_2';
  static const String typeField = 'type';

  /// Null unless the owner switched it on **and** gave it something to say.
  ///
  /// Two refusals, for the same reason the address lists read a malformed
  /// field as empty: the section is typed by hand into a console while
  /// something is already going wrong.
  ///
  /// - `enable` must be an explicit true. Anything else is off — a notice that
  ///   could be turned on by a typo is one that takes the app away by typo.
  /// - `title` must carry text. A notice with a blank headline replaces a
  ///   working app with a screen that says nothing, which is strictly worse
  ///   than not showing it.
  static ErrorViewConfig? fromMap(Map<String, Object?> data) {
    if (data[enableField] != true) return null;

    final String title = _text(data[titleField]);

    if (title.isEmpty) return null;

    return ErrorViewConfig(
      title: title,
      subtitle1: _text(data[subtitle1Field]),
      subtitle2: _text(data[subtitle2Field]),
      type: ErrorViewType.from(data[typeField]),
    );
  }

  /// Anything that is not a string is no text at all — and a string of spaces
  /// is the same thing typed by hand.
  static String _text(Object? value) =>
      value is String ? value.trim() : '';
}
