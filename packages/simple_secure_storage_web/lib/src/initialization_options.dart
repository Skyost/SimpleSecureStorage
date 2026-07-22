import 'package:flutter/foundation.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:simple_secure_storage_platform_interface/simple_secure_storage_platform_interface.dart';

/// Allows to pass specific options to the web implementation.
class WebInitializationOptions extends InitializationOptions {
  /// The key password.
  final String? _keyPassword;

  /// The encryption salt.
  final String? _encryptionSalt;

  /// The database factory.
  final DatabaseFactory databaseFactory;

  /// Timeout before auto closing the database.
  /// You'll have to call [SimpleSecureStorageWeb.initialize] after that.
  final Duration? autoCloseDatabaseTimeout;

  /// Will be called on database close.
  final Function? onDatabaseClosed;

  /// Creates a new web initialization options instance.
  WebInitializationOptions({
    String? appName,
    String? namespace,
    this._keyPassword,
    this._encryptionSalt,
    DatabaseFactory? databaseFactory,
    this.autoCloseDatabaseTimeout,
    this.onDatabaseClosed,
  }) : databaseFactory = databaseFactory ?? databaseFactoryWeb,
       super(
         appName: appName ?? 'Simple Secure Storage',
         namespace: namespace ?? 'fr.skyost.simple_secure_storage',
       );

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
    return '$namespace.$appName';
  }

  /// Returns the encryption salt, or a default value if not specified.
  String get encryptionSalt => _encryptionSalt ?? '_salt';

  @override
  String get appName => super.appName!;

  @override
  String get namespace => super.namespace!;

  @override
  WebInitializationOptions copyWith({
    String? appName,
    String? namespace,
    String? prefix,
    String? keyPassword,
    String? encryptionSalt,
    DatabaseFactory? databaseFactory,
    Duration? autoCloseDatabaseTimeout,
    Function? onDatabaseClosed,
  }) => WebInitializationOptions(
    appName: appName ?? this.appName,
    namespace: namespace ?? this.namespace,
    keyPassword: keyPassword ?? _keyPassword,
    encryptionSalt: encryptionSalt ?? _encryptionSalt,
    databaseFactory: databaseFactory ?? this.databaseFactory,
    autoCloseDatabaseTimeout: autoCloseDatabaseTimeout ?? this.autoCloseDatabaseTimeout,
    onDatabaseClosed: onDatabaseClosed ?? this.onDatabaseClosed,
  );

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'keyPassword': ?_keyPassword,
    'encryptionSalt': ?_encryptionSalt,
  };
}

/// Allows to configure the plugin initialization for web.
extension ConfigureForWeb on InitializationOptions {
  /// Configures the plugin initialization for web.
  InitializationOptions configureForWeb({
    String? keyPassword,
    String? encryptionSalt,
    DatabaseFactory? databaseFactory,
    Duration? autoCloseDatabaseTimeout,
    Function? onDatabaseClosed,
  }) => kIsWeb
      ? WebInitializationOptions(
          appName: appName,
          namespace: namespace,
          keyPassword: keyPassword,
          encryptionSalt: encryptionSalt,
          databaseFactory: databaseFactory,
          autoCloseDatabaseTimeout: autoCloseDatabaseTimeout,
          onDatabaseClosed: onDatabaseClosed,
        )
      : copyWith();
}
