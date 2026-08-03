/// Where a label photo comes from: the camera, or the photo library.
enum MedicationPhotoOrigin { camera, gallery }

/// Takes (or picks) a photo and hands back its path on disk.
///
/// An interface so the scan flow can run in a widget test without a camera —
/// `image_picker` is the only implementation.
abstract interface class MedicationPhotoSource {
  /// The photo's file path, or null when the user backed out of the picker.
  Future<String?> pick(MedicationPhotoOrigin origin);
}
