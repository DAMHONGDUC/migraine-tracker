import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/services/text_recognizer.dart';

/// ML Kit's on-device text recognition.
///
/// On-device on purpose (hard rule 1): the photo of a medicine box is health
/// data, so it is read where it was taken and never uploaded. The image file
/// itself is the caller's — nothing here keeps a copy.
class MlKitMedicationTextRecognizer implements MedicationTextRecognizer {
  MlKitMedicationTextRecognizer();

  final TextRecognizer _recognizer = TextRecognizer();

  @override
  Future<List<String>> recognize(String imagePath) async {
    final RecognizedText result = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );

    return <String>[
      for (final TextBlock block in result.blocks)
        for (final TextLine line in block.lines) line.text,
    ];
  }

  /// Frees the native detector. The provider that owns this calls it on
  /// dispose — ML Kit holds a native session per recognizer.
  Future<void> close() => _recognizer.close();
}
