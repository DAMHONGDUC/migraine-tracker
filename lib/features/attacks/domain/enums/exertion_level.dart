/// Self-reported physical exertion around the attack.
///
/// [none] is a real answer, not the absence of one — it is what the log
/// flow's exertion step starts on, so the common case (the user was not
/// exerting themselves) costs no taps. A null column means "never asked",
/// which only attacks logged before the step existed carry.
enum ExertionLevel { none, light, moderate, severe }
