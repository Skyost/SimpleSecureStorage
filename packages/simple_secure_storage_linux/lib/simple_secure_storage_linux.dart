import 'dart:convert' show jsonEncode, jsonDecode;

import 'package:freedesktop_secret/freedesktop_secret.dart';
import 'package:simple_secure_storage_platform_interface/simple_secure_storage_platform_interface.dart';

typedef _StorageMap = Map<String, String>;

/// Linux implementation of SimpleSecureStorage using the `org.freedesktop.secrets` D-Bus API.
class SimpleSecureStorageLinux extends SimpleSecureStoragePlatform {
  /// Registers this class as the default instance of [SimpleSecureStoragePlatform].
  static void registerWith() =>
      SimpleSecureStoragePlatform.instance = SimpleSecureStorageLinux();

  /// Secret Service client (`org.freedesktop.secrets`).
  final FreeDesktopSecret _client = FreeDesktopSecret();

  /// Storage identifier.
  String? _dataKey;

  /// Returns the storage identifier or throws if uninitialized.
  String get _requireDataKey =>
      _dataKey ??
      (throw StateError(
        'SimpleSecureStorage must be initialized before accessing storage.',
      ));

  /// Optional prefix applied to all storage keys.
  ///
  /// Loaded from [InitializationOptions.prefix] during [initialize] and used to
  /// namespace keys within the underlying storage map.
  String? _prefix;
  String _applyPrefix(String key) => '${_prefix ?? ''}$key';

  /// Returns the attributes used for storing and identifying secrets.
  ///
  /// These attributes must remain unchanged to preserve compatibility with secrets
  /// created by the previous GNOME libsecret-based implementation:
  /// https://github.com/Skyost/SimpleSecureStorage/blob/5940541cbb2a457a43735a6047434354c49bf77e/packages/simple_secure_storage_linux/linux/simple_secure_storage_linux_plugin.cc#L27-L36
  Map<String, String> _lookupAttributes() => {
    'xdg:schema': 'fr.skyost.SimpleSecureStorage',
    'data': _requireDataKey,
  };

  /// Reads and decodes the stored key/value map.
  Future<_StorageMap> _readStorageMap() async {
    final secret = await _client.lookupSecret(
      attributes: _lookupAttributes(),
      duplicateStrategy: LookupSecretDuplicateStrategy.newestCreated,
    );
    return secret == null ? {} : secret.storageMap();
  }

  /// Encodes and stores the key/value map.
  Future<void> _writeStorageMap(_StorageMap map) async {
    await _client.storeSecretText(
      attributes: _lookupAttributes(),
      label: _requireDataKey,
      secret: jsonEncode(map),
      replace: true,
    );
  }

  /// Initializes the plugin.
  Future<void> initialize(InitializationOptions options) async {
    await _client.initialize();

    _prefix = options.prefix;

    var app = options.appName ?? 'Simple Secure Storage';

    if (options.namespace != null) {
      app = '${options.namespace}.$app';
    }

    _dataKey = app.replaceAll(' ', '');
  }

  /// Clears all values.
  @override
  Future<void> clear() => _writeStorageMap({});

  /// Deletes the value associated to the given [key].
  @override
  Future<void> delete(String key) async {
    final map = await _readStorageMap();
    map.remove(_applyPrefix(key));

    await _writeStorageMap(map);
  }

  /// Returns whether the secure storage has the given [key].
  @override
  Future<bool> has(String key) async {
    final map = await _readStorageMap();
    return map.containsKey(_applyPrefix(key));
  }

  /// Lists all key/value pairs.
  @override
  Future<Map<String, String>> list() async {
    final map = await _readStorageMap();
    final prefix = _prefix;

    if (prefix == null || prefix.isEmpty) {
      return map;
    }

    return map.map(
      (key, value) => MapEntry(key.substring(prefix.length), value),
    );
  }

  /// Returns the value of the given [key].
  @override
  Future<String?> read(String key) async {
    final map = await _readStorageMap();
    return map[_applyPrefix(key)];
  }

  /// Writes the [value] so that it corresponds to the [key].
  @override
  Future<void> write(String key, String value) async {
    final map = await _readStorageMap();
    map[_applyPrefix(key)] = value;

    await _writeStorageMap(map);
  }
}

extension on SecretItem {
  /// Decodes the stored key/value map.
  _StorageMap storageMap() =>
      (jsonDecode(secretAsText()) as Map<String, Object?>).cast();
}
