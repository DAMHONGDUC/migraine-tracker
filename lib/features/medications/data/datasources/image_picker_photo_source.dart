import 'package:image_picker/image_picker.dart';

import '../../domain/services/medication_photo_source.dart';

/// `image_picker`-backed [MedicationPhotoSource]: the OS camera or photo
/// library, whichever the user asked for.
///
/// The photo stays where the picker put it (a temp file the OS owns) and is
/// read once for text — nothing copies it into the app's documents, because
/// a picture of a medicine box is health data and the wipe would then have
/// to chase it (hard rule 8).
class ImagePickerPhotoSource implements MedicationPhotoSource {
  ImagePickerPhotoSource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(MedicationPhotoOrigin origin) async {
    final XFile? file = await _picker.pickImage(
      source: origin == MedicationPhotoOrigin.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // A label only has to be legible to the recognizer; a full-resolution
      // photo is slower to read and larger to hold in memory.
      maxWidth: 2000,
      imageQuality: 90,
    );

    return file?.path;
  }
}
