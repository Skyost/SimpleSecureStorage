// ignore: avoid_web_libraries_in_flutter
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:simple_secure_storage_platform_interface/simple_secure_storage_platform_interface.dart';
import 'package:simple_secure_storage_web/src/crypto.dart';
import 'package:simple_secure_storage_web/src/initialization_options.dart';

/// A web implementation of the SimpleSecureStoragePlatform of the SimpleSecureStorage plugin.
class SimpleSecureStorageWeb extends SimpleSecureStoragePlatform {
  /// The store instance.
  StoreRef<String, Object?>? _store;

  /// The database instance.
  Database? _database;

  /// The database factory.
  EncryptedDatabaseFactory? _factory;

  /// Delay before auto closing.
  Duration? _autoCloseDelay;

  /// Will be triggered when [close] is being called.
  Function? _onClosed;

  /// Registers this implementation.
  static void registerWith(Registrar registrar) => SimpleSecureStoragePlatform.instance = SimpleSecureStorageWeb();

  @override
  Future<void> initialize(InitializationOptions options) async {
    WebInitializationOptions webOptions = options is WebInitializationOptions ? options : WebInitializationOptions.from(options);
    if (_factory == null) {
      _factory = EncryptedDatabaseFactory(
        databaseFactory: databaseFactoryWeb,
        password: webOptions.keyPassword,
        salt: webOptions.encryptionSalt,
      );
    }
    if (_database == null) {
      _database = await _factory!.openDatabase(webOptions.namespace, version: 1);
    }
    if (_store == null) {
      _store = stringMapStoreFactory.store();
    }
  }

  @override
  Future<bool> has(String key) async {
    _ensureInitialized();
    bool result = (await _store!.record(key).get(_database!)) != null;
    _throttleAutoClose();
    return result;
  }

  @override
  Future<String?> read(String key) async {
    _ensureInitialized();
    String? result = (await _store!.record(key).get(_database!))?.toString();
    _throttleAutoClose();
    return result;
  }

  @override
  Future<Map<String, String>> list() async {
    _ensureInitialized();
    List<RecordSnapshot<String, Object?>> records = await _store!.find(_database!);
    Map<String, String> result = {
      for (RecordSnapshot<String, Object?> record in records)
        if (record.value != null) record.key: record.value.toString()
    };
    _throttleAutoClose();
    return result;
  }

  @override
  Future<void> write(String key, String value) async {
    _ensureInitialized();
    await _store!.record(key).put(_database!, value);
    _throttleAutoClose();
  }

  @override
  Future<void> delete(String key) async {
    _ensureInitialized();
    await _store!.record(key).delete(_database!);
    _throttleAutoClose();
  }

  @override
  Future<void> clear() async {
    _ensureInitialized();
    await _store!.delete(_database!);
    _throttleAutoClose();
  }

  /// Closes the database.
  Future<void> close() async {
    await _database!.close();
    _database = null;
    _onClosed?.call();
  }

  /// Throttles auto closing.
  void _throttleAutoClose() {
    if (_autoCloseDelay != null) {
      Throttle.duration(_autoCloseDelay!, close);
    }
  }

  /// Ensures the plugin has been initialized.
  void _ensureInitialized() {
    assert(_store != null && _factory != null && _database != null, 'Please make sure you have initialized the plugin.');
  }
}
