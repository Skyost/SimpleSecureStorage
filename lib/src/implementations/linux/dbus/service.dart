// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object org.freedesktop.Secret.Service.xml

import 'dart:io';
import 'package:dbus/dbus.dart';

/// Signal data for org.freedesktop.Secret.Service.CollectionCreated.
class OrgFreedesktopSecretServiceCollectionCreated extends DBusSignal {
  DBusObjectPath get collection => values[0].asObjectPath();

  OrgFreedesktopSecretServiceCollectionCreated(DBusSignal signal) : super(sender: signal.sender, path: signal.path, interface: signal.interface, name: signal.name, values: signal.values);
}

/// Signal data for org.freedesktop.Secret.Service.CollectionDeleted.
class OrgFreedesktopSecretServiceCollectionDeleted extends DBusSignal {
  DBusObjectPath get collection => values[0].asObjectPath();

  OrgFreedesktopSecretServiceCollectionDeleted(DBusSignal signal) : super(sender: signal.sender, path: signal.path, interface: signal.interface, name: signal.name, values: signal.values);
}

/// Signal data for org.freedesktop.Secret.Service.CollectionChanged.
class OrgFreedesktopSecretServiceCollectionChanged extends DBusSignal {
  DBusObjectPath get collection => values[0].asObjectPath();

  OrgFreedesktopSecretServiceCollectionChanged(DBusSignal signal) : super(sender: signal.sender, path: signal.path, interface: signal.interface, name: signal.name, values: signal.values);
}

class OrgFreedesktopSecretService extends DBusRemoteObject {
  /// Stream of org.freedesktop.Secret.Service.CollectionCreated signals.
  late final Stream<OrgFreedesktopSecretServiceCollectionCreated> collectionCreated;

  /// Stream of org.freedesktop.Secret.Service.CollectionDeleted signals.
  late final Stream<OrgFreedesktopSecretServiceCollectionDeleted> collectionDeleted;

  /// Stream of org.freedesktop.Secret.Service.CollectionChanged signals.
  late final Stream<OrgFreedesktopSecretServiceCollectionChanged> collectionChanged;

  OrgFreedesktopSecretService(DBusClient client, String destination, DBusObjectPath path) : super(client, name: destination, path: path) {
    collectionCreated = DBusRemoteObjectSignalStream(object: this, interface: 'org.freedesktop.Secret.Service', name: 'CollectionCreated', signature: DBusSignature('o')).asBroadcastStream().map((signal) => OrgFreedesktopSecretServiceCollectionCreated(signal));

    collectionDeleted = DBusRemoteObjectSignalStream(object: this, interface: 'org.freedesktop.Secret.Service', name: 'CollectionDeleted', signature: DBusSignature('o')).asBroadcastStream().map((signal) => OrgFreedesktopSecretServiceCollectionDeleted(signal));

    collectionChanged = DBusRemoteObjectSignalStream(object: this, interface: 'org.freedesktop.Secret.Service', name: 'CollectionChanged', signature: DBusSignature('o')).asBroadcastStream().map((signal) => OrgFreedesktopSecretServiceCollectionChanged(signal));
  }

  /// Gets org.freedesktop.Secret.Service.Collections
  Future<List<DBusObjectPath>> getCollections() async {
    var value = await getProperty('org.freedesktop.Secret.Service', 'Collections', signature: DBusSignature('ao'));
    return value.asObjectPathArray().toList();
  }

  /// Invokes org.freedesktop.Secret.Service.OpenSession()
  Future<List<DBusValue>> callOpenSession(String algorithm, DBusValue input, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Service', 'OpenSession', [DBusString(algorithm), DBusVariant(input)], replySignature: DBusSignature('vo'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues;
  }

  /// Invokes org.freedesktop.Secret.Service.CreateCollection()
  Future<List<DBusValue>> callCreateCollection(Map<String, DBusValue> properties, String alias, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Service', 'CreateCollection', [DBusDict.stringVariant(properties), DBusString(alias)], replySignature: DBusSignature('oo'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues;
  }

  /// Invokes org.freedesktop.Secret.Service.SearchItems()
  Future<List<DBusValue>> callSearchItems(Map<String, String> attributes, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Service', 'SearchItems', [DBusDict(DBusSignature('s'), DBusSignature('s'), attributes.map((key, value) => MapEntry(DBusString(key), DBusString(value))))], replySignature: DBusSignature('aoao'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues;
  }

  /// Invokes org.freedesktop.Secret.Service.Unlock()
  Future<List<DBusValue>> callUnlock(List<DBusObjectPath> objects, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Service', 'Unlock', [DBusArray.objectPath(objects)], replySignature: DBusSignature('aoo'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues;
  }

  /// Invokes org.freedesktop.Secret.Service.Lock()
  Future<List<DBusValue>> callLock(List<DBusObjectPath> objects, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Service', 'Lock', [DBusArray.objectPath(objects)], replySignature: DBusSignature('aoo'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues;
  }

  /// Invokes org.freedesktop.Secret.Service.LockService()
  Future<void> callLockService({bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.freedesktop.Secret.Service', 'LockService', [], replySignature: DBusSignature(''), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.freedesktop.Secret.Service.ChangeLock()
  Future<DBusObjectPath> callChangeLock(DBusObjectPath collection, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Service', 'ChangeLock', [collection], replySignature: DBusSignature('o'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPath();
  }

  /// Invokes org.freedesktop.Secret.Service.GetSecrets()
  Future<Map<DBusObjectPath, List<DBusValue>>> callGetSecrets(List<DBusObjectPath> items, DBusObjectPath session, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Service', 'GetSecrets', [DBusArray.objectPath(items), session], replySignature: DBusSignature('a{o(oayays)}'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asDict().map((key, value) => MapEntry(key.asObjectPath(), value.asStruct()));
  }

  /// Invokes org.freedesktop.Secret.Service.ReadAlias()
  Future<DBusObjectPath> callReadAlias(String name, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Service', 'ReadAlias', [DBusString(name)], replySignature: DBusSignature('o'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPath();
  }

  /// Invokes org.freedesktop.Secret.Service.SetAlias()
  Future<void> callSetAlias(String name, DBusObjectPath collection, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.freedesktop.Secret.Service', 'SetAlias', [DBusString(name), collection], replySignature: DBusSignature(''), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
  }
}
