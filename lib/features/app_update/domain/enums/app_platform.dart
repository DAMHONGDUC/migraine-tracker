/// The platforms an update record carries a section for. Deliberately not
/// Flutter's `TargetPlatform`: this is the shape of the Firestore document,
/// which only ever describes the two stores we ship to.
enum AppPlatform { android, ios }
