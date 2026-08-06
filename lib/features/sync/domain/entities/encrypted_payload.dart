import 'package:meta/meta.dart';

/// An AES-GCM ciphertext and everything needed to open it again, all base64.
///
/// The nonce is fresh per write and the MAC authenticates the ciphertext, so
/// a payload tampered with in transit or at rest fails to decrypt rather than
/// decoding to something plausible.
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
