import 'package:dbus/dbus.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:simple_secure_storage/simple_secure_storage.dart';
import 'package:simple_secure_storage/src/implementations/linux/dbus/collection.dart';
import 'package:simple_secure_storage/src/implementations/linux/dbus/item.dart';
import 'package:simple_secure_storage/src/implementations/linux/dbus/service.dart';

/// A Linux implementation of the SimpleSecureStoragePlatform of the SimpleSecureStorage plugin.
class SimpleSecureStorageLinux extends SimpleSecureStoragePlatform {
  /// The DBus client.
  final DBusClient _client = DBusClient.system();

  /// The service instance.
  late final OrgFreedesktopSecretService _service;

  /// The collections instance.
  late final OrgFreedesktopSecretCollection _collection;

  /// The session instance.
  late final DBusObjectPath _session;

  /// Constructs a SimpleSecureStorageLinux.
  SimpleSecureStorageLinux();

  /// Registers this implementation.
  static void registerWith(Registrar registrar) {
    SimpleSecureStoragePlatform.instance = SimpleSecureStorageLinux();
  }

  @override
  Future<void> initialize({String? namespace}) async {
    String name = namespace ?? 'fr.skyost.simple_secure_storage';
    _service = OrgFreedesktopSecretService(_client, 'org.freedesktop.secrets', DBusObjectPath('/'));
    await _service.callCreateCollection(
      {
        'label': DBusString(name),
        'private': const DBusBoolean(true),
      },
      name,
    );
    _session = (await _service.callOpenSession('plain', const DBusString('')))[1] as DBusObjectPath;
    _collection = OrgFreedesktopSecretCollection(
      _client,
      'org.freedesktop.Secrets',
      DBusObjectPath('/$name'),
    );
  }

  @override
  Future<bool> has(String key) async => (await _collection.callSearchItems({'key': key})).isNotEmpty;

  @override
  Future<String?> read(String key) async {
    List<DBusObjectPath>? result = await _collection.callSearchItems({'key': key});
    if (result.isEmpty) {
      return null;
    }
    OrgFreedesktopSecretItem item = OrgFreedesktopSecretItem(_client, '/', result.first);
    List<DBusValue> secret = await item.callGetSecret(_session);
    if (secret.isEmpty) {
      return null;
    }
    return secret.first.toString();
  }

  @override
  Future<void> write(String key, String value) async {
    _collection.callCreateItem(
      {
        'org.freedesktop.Secret.Item.Label': DBusString(key),
        'org.freedesktop.Secret.Item.Attributes': DBusDict.stringVariant({'value': DBusString(value)}),
      },
      [],
      true,
    );
  }

  @override
  Future<bool> delete(String key) async {
    List<DBusObjectPath>? result = await _collection.callSearchItems({'key': key});
    if (result.isEmpty) {
      return false;
    }
    OrgFreedesktopSecretItem item = OrgFreedesktopSecretItem(_client, '/', result.first);
    await item.callDelete();
    return true;
  }

  @override
  Future<bool> clear() async {
    await _collection.callDelete();
    return true;
  }
}
