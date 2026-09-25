import 'dart:io';

import 'package:simple_secure_storage_platform_interface/simple_secure_storage_platform_interface.dart';
import 'package:linux_application_id/linux_application_id.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';
import 'package:xdg_directories/xdg_directories.dart' as xdg_directories;
import 'package:xdg_secret_portal_store/xdg_secret_portal_store.dart';
import 'package:xdg_secret_portal_store_default/xdg_secret_portal_store_default.dart';

typedef _StorageMap = Map<String, String>;

/// A Linux implementation of [SimpleSecureStoragePlatform] using the
/// XDG Desktop Portal Secret API ([`org.freedesktop.portal.Secret`](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Secret.html)).
///
/// [SimpleSecureStorageLinuxPortal.registerWith] must be explicitly called.
/// Simply adding the package as a dependency is not sufficient.
class SimpleSecureStorageLinuxPortal extends SimpleSecureStoragePlatform {
  /// Registers this class as the default instance of [SimpleSecureStoragePlatform].
  static void registerWith() =>
      SimpleSecureStoragePlatform.instance = SimpleSecureStorageLinuxPortal();

  /// A helper for storing application secrets in an encrypted file using the
  /// master secret provided by the XDG Desktop Portal Secret API.
  XdgSecretPortalStore? _store;
  XdgSecretPortalStore get _requireStore =>
      _store ??
      (throw StateError(
        'SimpleSecureStorage must be initialized before accessing storage.',
      ));

  /// Overrides the Linux application ID.
  ///
  /// If null, the application ID of the running GLib `GApplication` is used.
  ///
  /// The application ID is used to determine the directory where the encrypted
  /// secret store is persisted.
  String? applicationIdOverride;
  String get _applicationId =>
      applicationIdOverride ??
      linuxApplicationId() ??
      (throw UnsupportedError(
        'No Linux application ID is available. This must be called from a running Flutter Linux application.',
      ));

  /// Optional prefix applied to all storage keys.
  ///
  /// Loaded from [InitializationOptions.prefix] during [initialize] and used to
  /// namespace keys within the underlying storage map.
  String? _prefix;
  String _applyPrefix(String key) => '${_prefix ?? ''}$key';

  Future<_StorageMap> _readStorageMap() => _requireStore.read();
  Future<void> _writeStorageMap(_StorageMap map) => _requireStore.write(map);

  @override
  Future<void> initialize(InitializationOptions options) async {
    _prefix = options.prefix;

    final client = XdgDesktopPortalClient();

    final store = XdgSecretPortalStore(
      masterSecretRetriever: client.secret.retrieveSecret,
      persistence: SecretStorePersistenceFile(
        File(
          '${xdg_directories.dataHome.path}/$_applicationId/secure_storage/secrets.json',
        ),
      ),
      crypto: SecretStoreCryptoDefault(),
    );

    await store.loadMasterSecret();
    await client.close();

    _store = store;
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
