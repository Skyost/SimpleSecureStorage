import 'dart:convert';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:sembast/src/api/v2/sembast.dart';
import 'package:webcrypto/webcrypto.dart';

/// Wrap a factory to always use the codec
class EncryptedDatabaseFactory implements DatabaseFactory {
  /// Our plain text signature
  static const String _encryptCodecSignature = 'encrypt';

  /// The database factory.
  final DatabaseFactory databaseFactory;

  /// The password.
  final String password;

  /// The salt.
  final String salt;

  /// The codec.
  SembastCodec? codec;

  /// Creates a new encrypted database factory instance.
  EncryptedDatabaseFactory({
    required this.databaseFactory,
    required this.password,
    required this.salt,
  });

  @override
  Future<void> deleteDatabase(String path) => databaseFactory.deleteDatabase(path);

  @override
  bool get hasStorage => databaseFactory.hasStorage;

  /// To use with codec, null
  @override
  Future<Database> openDatabase(String path, {int? version, OnVersionChangedFunction? onVersionChanged, DatabaseMode? mode, SembastCodec? codec}) async {
    assert(codec == null);
    codec ??= (await _getEncryptSembastCodec(password: password, salt: salt));
    return databaseFactory.openDatabase(path, version: version, onVersionChanged: onVersionChanged, mode: mode, codec: this.codec);
  }

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
  Future<SembastCodec> _getEncryptSembastCodec({
    required String password,
    required String salt,
  }) async {
    Uint8List digest = await Hash.sha256.digestBytes(utf8.encode(password));
    Pbkdf2SecretKey secretKey = await Pbkdf2SecretKey.importRawKey(digest);
    Uint8List key = await secretKey.deriveBits(
      256,
      Hash.sha256,
      utf8.encode(salt),
      100000,
    );
    return SembastCodec(
      signature: _encryptCodecSignature,
      codec: _EncryptCodec(await AesGcmSecretKey.importRawKey(key)),
    );
  }
}

/// AES-GCM based codec.
class _EncryptCodec extends AsyncContentCodecBase {
  /// The initialization vector length.
  static const int initializationVectorLength = 16;

  /// The encoded initialization vector length.
  static const int encodedInitializationVectorLength = 24;

  /// The key instance.
  final AesGcmSecretKey key;

  /// Creates a new encrypt codec instance.
  _EncryptCodec(this.key);

  @override
  Future<Object?> decodeAsync(String encoded) async {
    // Read the initial value that was prepended
    assert(encoded.length >= encodedInitializationVectorLength);
    Uint8List initializationVector = base64.decode(encoded.substring(0, encodedInitializationVectorLength));

    // Extract the real input
    encoded = encoded.substring(encodedInitializationVectorLength);

    // Decode the input
    dynamic decoded = json.decode(utf8.decode(await key.decryptBytes(base64.decode(encoded), initializationVector)));
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
    return decoded;
  }

  @override
  Future<String> encodeAsync(Object? input) async {
    // Generate random initial value
    Uint8List initializationVector = Uint8List(initializationVectorLength);
    fillRandomBytes(initializationVector);
    String ivEncoded = base64.encode(initializationVector);
    assert(ivEncoded.length == encodedInitializationVectorLength);

    // Encode the input value
    String encoded = base64.encode(await key.encryptBytes(utf8.encode(json.encode(input)), initializationVector));

    // Prepend the initial value
    return '$ivEncoded$encoded';
  }
}
