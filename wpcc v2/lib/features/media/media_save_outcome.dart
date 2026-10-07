/// What happened when the user asked to save a file.
enum SaveOutcome {
  /// Written to a place the user picked, or downloaded by the browser.
  saved,

  /// Handed to the system share sheet (on a phone this offers Save to Photos
  /// or Gallery).
  shared,

  /// The user closed the picker or share sheet without choosing anything.
  cancelled,
}
