/// How a receipt file ended up with the member.
enum ReceiptSaveOutcome {
  /// Handed to the system share sheet (Save to Photos / Files on phones).
  shared,

  /// Written to a location the member picked.
  saved,

  /// Downloaded through the browser's normal download flow.
  downloaded,

  /// The member closed the share sheet or save dialog.
  cancelled,
}
