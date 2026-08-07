/// What asked for a sync — which decides whether it may be skipped.
///
/// [automatic] fires on every launch and every resume, so ten app opens in
/// ten minutes were ten full passes before this existed. It is the only one
/// held back, and the other two are exempt for reasons that are not the same:
///
/// - [manual] is the user asking in as many words, watching the screen for
///   the answer.
/// - [record] exists so a freshly logged attack reaches the server before
///   the phone can be lost (hard rule 12) — it is the one trigger whose whole
///   point is not waiting.
enum SyncTrigger { automatic, manual, record }
