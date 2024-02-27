// ignore: avoid_web_libraries_in_flutter
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:simple_secure_storage_platform_interface/simple_secure_storage_platform_interface.dart';
import 'package:simple_secure_storage_web/src/crypto.dart';
import 'package:simple_secure_storage_web/src/initialization_options.dart';

/// A web implementation of the SimpleSecureStoragePlatform of the SimpleSecureStorage plugin.
class SimpleSecureStorageWeb extends SimpleSecureStoragePlatform {
  /// The store instance.
  StoreRef<String, Object?>? store;

  /// The database instance.
  Database? database;

  /// Registers this implementation.
  static void registerWith(Registrar registrar) => SimpleSecureStoragePlatform.instance = SimpleSecureStorageWeb();

  @override
  Future<void> initialize(InitializationOptions options) async {
    WebInitializationOptions webOptions = options is WebInitializationOptions ? options : WebInitializationOptions.from(options);
    EncryptedDatabaseFactory factory = EncryptedDatabaseFactory(
      databaseFactory: databaseFactoryWeb,
      password: webOptions.keyPassword,
      salt: webOptions.encryptionSalt,
    );
    store = stringMapStoreFactory.store();
    database = await factory.openDatabase(webOptions.namespace, version: 1);
  }

  @override
  Future<bool> has(String key) async {
    ensureInitialized();
    return (await store!.record(key).get(database!)) != null;
  }

  @override
  Future<String?> read(String key) async {
    ensureInitialized();
    return (await store!.record(key).get(database!))?.toString();
  }

  @override
  Future<Map<String, String>> list() async {
    ensureInitialized();
    List<RecordSnapshot<String, Object?>> records = await store!.find(database!);
    return {
      for (RecordSnapshot<String, Object?> record in records)
        if (record.value != null) record.key: record.value.toString()
    };
  }

  @override
  Future<void> write(String key, String value) async {
    ensureInitialized();
    await store!.record(key).put(database!, value);
  }

  @override
  Future<void> delete(String key) async {
    ensureInitialized();
    await store!.record(key).delete(database!);
  }

  @override
  Future<void> clear() async {
    ensureInitialized();
    await store!.delete(database!);
  }

  /// Closes the database.
  Future<void> close() async {
    await database!.close();
    database = null;
  }

  /// Ensures the plugin has been initialized.
  void ensureInitialized() {
    assert(store != null && database != null, 'Please make sure you have initialized the plugin.');
  }
}
