/// The kinds of aura a person can report for themselves.
///
/// ICHD-3 names six; these are the four somebody can recognise without a
/// neurologist in the room. Retinal and brainstem aura are left out on
/// purpose: both need a clinician to distinguish from the two above them,
/// and an app that offers them invites a self-diagnosis it cannot support.
///
/// **Never asked during the log flow** (hard rule 5). Aura runs *before* the
/// pain in most people, so at the moment an attack is logged it is already
/// over — it is recorded after the fact from the detail screen, the same way
/// `endedAt` and `medicationEffect` are.
enum AuraType {
  /// Zigzags, blind spots, flashing lights — around nine in ten auras.
  visual,

  /// Pins and needles or numbness, usually spreading up one arm or side.
  sensory,

  /// Trouble finding or forming words.
  speech,

  /// Weakness on one side. Worth its own answer because it changes what a
  /// doctor does next, and because people describe it as "my arm went dead"
  /// rather than as an aura at all.
  motor,
}
