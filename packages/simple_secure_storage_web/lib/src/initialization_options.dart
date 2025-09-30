import 'package:simple_secure_storage_platform_interface/simple_secure_storage_platform_interface.dart';

/// Allows to pass specific options to the web implementation.
class WebInitializationOptions extends InitializationOptions {
  /// The key password.
  final String? _keyPassword;

  /// The encryption salt.
  final String? _encryptionSalt;

  /// Timeout before auto closing the database.
  /// You'll have to call [SimpleSecureStorageWeb.initialize] after that.
  final Duration? autoCloseDatabaseTimeout;

  /// Will be called on database close.
  final Function()? onDatabaseClosed;

  /// Creates a new web initialization options instance.
  WebInitializationOptions({
    super.appName,
    super.namespace,
    String? keyPassword,
    String? encryptionSalt,
    this.autoCloseDatabaseTimeout,
    this.onDatabaseClosed,
  })  : _keyPassword = keyPassword,
        _encryptionSalt = encryptionSalt;

  /// Creates a new web initialization options instance.
  WebInitializationOptions.from(InitializationOptions options)
      : this(
          appName: options.appName,
          namespace: options.namespace,
        );

  /// Returns the key password, or a default value if not specified.
  String get keyPassword {
    if (_keyPassword != null) {
      return _keyPassword;
    }
    String namespaceString = namespace;
    String appNameString = appName ?? 'Simple Secure Storage';
    return '$namespaceString.$appNameString';
  }

  /// Returns the encryption salt, or a default value if not specified.
  String get encryptionSalt => _encryptionSalt ?? '_salt';

  /// Returns the namespace, or a default value if not specified.
  String get namespace => super.namespace ?? 'fr.skyost.simple_secure_storage';
}
