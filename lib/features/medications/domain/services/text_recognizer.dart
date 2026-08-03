/// Reads the text off a photo, on the device.
///
/// An interface so the scan flow can be tested without a camera or ML Kit,
/// and so the recognizer behind it can be swapped without touching the
/// parser or the form.
abstract interface class MedicationTextRecognizer {
  /// Every line of text found in the image at [imagePath], in reading order.
  /// Empty when the photo has no legible text — that is an outcome, not an
  /// error.
  Future<List<String>> recognize(String imagePath);
}
