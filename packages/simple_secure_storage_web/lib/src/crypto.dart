import 'dart:convert';
import 'dart:typed_data';

import 'package:cipherlib/cipherlib.dart';
import 'package:cipherlib/hashlib.dart';
import 'package:cipherlib/random.dart';
import 'package:sembast/sembast.dart';

/// Create a codec to use to open a database with encrypted stored data.
///
/// Hash (md5) of the password is used (but never stored) as a key to encrypt
/// the data using the Salsa20 algorithm with a random (8 bytes) initial value
///
/// This is just used as a demonstration and should not be considered as a
/// reference since its implementation (and storage format) might change.
///
/// No performance metrics has been made to check whether this is a viable
/// solution for big databases.
///
/// The usage is then
///
/// ```dart
/// // Initialize the encryption codec with a user password
/// var codec = getEncryptSembastCodec(password: '[your_user_password]');
/// // Open the database with the codec
/// Database db = await factory.openDatabase(dbPath, codec: codec);
///
/// // ...your database is ready to use
/// ```
SembastCodec getEncryptSembastCodec({
  required String password,
  required String salt,
}) {
  Uint8List digest = sha256.string(password, utf8).bytes;
  Uint8List key = Uint8List.fromList(
    pbkdf2(
      digest,
      utf8.encode(salt),
      100000,
      32,
    ).bytes,
  );
  return SembastCodec(
    signature: 'encrypt',
    codec: _EncryptCodec(AES(key)),
  );
}

/// AES-GCM based codec.
class _EncryptCodec extends AsyncContentCodecBase {
  /// The initialization vector length.
  static const int initializationVectorLength = 16;

  /// The encoded initialization vector length.
  static const int encodedInitializationVectorLength = 24;

  /// The [AES] instance.
  final AES aes;

  /// Creates a new encrypt codec instance.
  _EncryptCodec(this.aes);

  @override
  Future<Object?> decodeAsync(String encoded) async {
    // Read the initial value that was prepended.
    assert(encoded.length >= encodedInitializationVectorLength);
    Uint8List initializationVector = base64.decode(encoded.substring(0, encodedInitializationVectorLength));

    // Extract the real input.
    encoded = encoded.substring(encodedInitializationVectorLength);

    // Decode the input.
    dynamic decoded = json.decode(utf8.decode(await aes.gcm(initializationVector).decrypt(base64Decode(encoded))));
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
    return decoded;
  }

  @override
  Future<String> encodeAsync(Object? input) async {
    // Generate random initial value.
    Uint8List initializationVector = randomBytes(initializationVectorLength);
    String ivEncoded = base64.encode(initializationVector);
    assert(ivEncoded.length == encodedInitializationVectorLength);

    // Encode the input value.
    String encoded = base64.encode(await aes.gcm(initializationVector).encrypt(utf8.encode(json.encode(input))));

    // Prepend the initial value.
    return '$ivEncoded$encoded';
  }
}
