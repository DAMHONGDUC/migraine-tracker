import 'package:meta/meta.dart';

/// An AES-GCM ciphertext and everything needed to open it again, all base64.
@immutable
class EncryptedPayload {
  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });

  final String ciphertext;
  final String nonce;
  final String mac;

  @override
  bool operator ==(Object other) =>
      other is EncryptedPayload &&
      other.ciphertext == ciphertext &&
      other.nonce == nonce &&
      other.mac == mac;

  @override
  int get hashCode => Object.hash(ciphertext, nonce, mac);
}
