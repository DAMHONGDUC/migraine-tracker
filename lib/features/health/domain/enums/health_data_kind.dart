/// Which Apple Health source a connection covers.
///
/// Separately connectable on purpose: sleep is about the night and steps
/// about the day, and someone happy to let the app read one may not want it
/// reading the other. One sheet each, so a refusal costs only its own source.
enum HealthDataKind { sleep, steps }
