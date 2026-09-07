import '../entities/app_config.dart';

/// The owner-managed `app_config/current` document — one read for every switch the app has.
abstract interface class AppConfigRepository {
  /// The live document, so throwing a switch or editing a list takes effect without a reinstall. Emits [AppConfig.empty] while it does not exist, which is the normal state of a project nobody has configured.
  ///
  /// Takes no address: the document is the same for everybody, and membership is decided on the client against the lists it carries.
  Stream<AppConfig> watch();
}
