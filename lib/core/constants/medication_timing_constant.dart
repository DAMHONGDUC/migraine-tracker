/// The offsets the "how long did it take to work?" sheet offers.
final class MedicationTimingConstant {
  /// How long after the attack started the dose was swallowed. Ends at 6h: past that the dose is treating a second wave, not this attack's onset.
  static const List<Duration> takenOptions = <Duration>[
    Duration.zero,
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 6),
  ];

  /// How long after the dose the pain eased. Ends at 4h because a triptan that has not worked in four hours has not worked — that is the clinical read, and the app must not invite a guess past it.
  static const List<Duration> reliefOptions = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 3),
    Duration(hours: 4),
  ];
}
