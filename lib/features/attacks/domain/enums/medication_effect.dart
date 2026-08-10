/// Whether the medication taken for an attack actually helped.
///
/// Three answers and not a yes/no, because "took the edge off" is the most
/// common outcome of an abortive and is the one a doctor acts on: a drug that
/// only ever partly works is a drug being changed.
///
/// Null on an attack means the question was never answered — either nothing
/// was taken, or the user has not said yet. It is never asked during the log
/// flow: at the moment an attack is logged the medication has not had time to
/// work (hard rule 5).
enum MedicationEffect { helped, partly, didNotHelp }
