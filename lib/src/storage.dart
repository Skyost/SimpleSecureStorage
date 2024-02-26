import 'package:simple_secure_storage/src/platform_interface.dart';

/// Base class of SimpleSecureStorage, allowing CRUD operations.
class SimpleSecureStorage {
  /// Initializes the plugin.
  static Future<void> initialize({
    String? appName,
    String? namespace,
  }) =>
      SimpleSecureStoragePlatform.instance.initialize(
        appName: appName,
        namespace: namespace,
      );

  /// Returns whether the secure storage has the given [key].
  static Future<bool> has(String key) => SimpleSecureStoragePlatform.instance.has(key);

  /// Returns the value of the given [key].
  static Future<String?> read(String key) => SimpleSecureStoragePlatform.instance.read(key);

  /// Lists all key/value pairs.
  static Future<Map<String, String>> list() => SimpleSecureStoragePlatform.instance.list();

  /// Writes the [value] so that it corresponds to the [key].
  static Future<void> write(String key, String value) => SimpleSecureStoragePlatform.instance.write(key, value);

  /// Deletes the value associated to the given [key].
  static Future<void> delete(String key) => SimpleSecureStoragePlatform.instance.delete(key);

  /// Clears all values.
  static Future<void> clear() => SimpleSecureStoragePlatform.instance.clear();
}
