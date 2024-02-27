import 'package:simple_secure_storage/src/storage.dart';

/// Allows to load and cache all values of the secure storage.
/// This means, no future and instant access of all your values.
class CachedSimpleSecureStorage extends SimpleSecureStorage {
  /// The cached simple secure storage instance.
  static CachedSimpleSecureStorage? _instance;

  /// The cached values.
  final Map<String, String> _cache = {};

  /// Creates a new cached simple secure storage instance.
  CachedSimpleSecureStorage._();

  /// Returns the cached simple secure storage instance.
  static Future<CachedSimpleSecureStorage> getInstance({
    String? appName,
    String? namespace,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    await SimpleSecureStorage.initialize(
      appName: appName,
      namespace: namespace,
    );

    CachedSimpleSecureStorage instance = CachedSimpleSecureStorage._();
    await instance.refreshCache();
    return instance;
  }

  /// Returns whether the secure storage has the given [key].
  bool has(String key) => _cache.containsKey(key);

  /// Returns the value of the given [key].
  String? read(String key) => _cache[key];

  /// Lists all key/value pairs.
  Map<String, String> list() => Map.of(_cache);

  /// Writes the [value] so that it corresponds to the [key].
  Future<void> write(String key, String value, {bool flush = true}) async {
    _cache[key] = value;
    if (flush) {
      await SimpleSecureStorage.write(key, value);
    }
  }

  /// Deletes the value associated to the given [key].
  Future<void> delete(String key, {bool flush = true}) async {
    _cache.remove(key);
    if (flush) {
      await SimpleSecureStorage.delete(key);
    }
  }

  /// Clears all values.
  Future<void> clear({bool flush = true}) async {
    _cache.clear();
    if (flush) {
      await SimpleSecureStorage.clear();
    }
  }

  /// Refreshes the cache.
  /// This can be useful if you access the storage data from outside this class.
  Future<void> refreshCache() async {
    _cache.clear();
    _cache.addAll(await SimpleSecureStorage.list());
  }
}
