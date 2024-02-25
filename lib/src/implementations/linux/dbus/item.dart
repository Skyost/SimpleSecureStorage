// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object org.freedesktop.Secret.Item.xml

import 'dart:io';
import 'package:dbus/dbus.dart';

class OrgFreedesktopSecretItem extends DBusRemoteObject {
  OrgFreedesktopSecretItem(DBusClient client, String destination, DBusObjectPath path) : super(client, name: destination, path: path);

  /// Gets org.freedesktop.Secret.Item.Locked
  Future<bool> getLocked() async {
    var value = await getProperty('org.freedesktop.Secret.Item', 'Locked', signature: DBusSignature('b'));
    return value.asBoolean();
  }

  /// Gets org.freedesktop.Secret.Item.Attributes
  Future<Map<String, String>> getAttributes() async {
    var value = await getProperty('org.freedesktop.Secret.Item', 'Attributes', signature: DBusSignature('a{ss}'));
    return value.asDict().map((key, value) => MapEntry(key.asString(), value.asString()));
  }

  /// Sets org.freedesktop.Secret.Item.Attributes
  Future<void> setAttributes (Map<String, String> value) async {
    await setProperty('org.freedesktop.Secret.Item', 'Attributes', DBusDict(DBusSignature('s'), DBusSignature('s'), value.map((key, value) => MapEntry(DBusString(key), DBusString(value)))));
  }

  /// Gets org.freedesktop.Secret.Item.Label
  Future<String> getLabel() async {
    var value = await getProperty('org.freedesktop.Secret.Item', 'Label', signature: DBusSignature('s'));
    return value.asString();
  }

  /// Sets org.freedesktop.Secret.Item.Label
  Future<void> setLabel (String value) async {
    await setProperty('org.freedesktop.Secret.Item', 'Label', DBusString(value));
  }

  /// Gets org.freedesktop.Secret.Item.Created
  Future<int> getCreated() async {
    var value = await getProperty('org.freedesktop.Secret.Item', 'Created', signature: DBusSignature('t'));
    return value.asUint64();
  }

  /// Gets org.freedesktop.Secret.Item.Modified
  Future<int> getModified() async {
    var value = await getProperty('org.freedesktop.Secret.Item', 'Modified', signature: DBusSignature('t'));
    return value.asUint64();
  }

  /// Invokes org.freedesktop.Secret.Item.Delete()
  Future<DBusObjectPath> callDelete({bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Item', 'Delete', [], replySignature: DBusSignature('o'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPath();
  }

  /// Invokes org.freedesktop.Secret.Item.GetSecret()
  Future<List<DBusValue>> callGetSecret(DBusObjectPath session, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.Secret.Item', 'GetSecret', [session], replySignature: DBusSignature('(oayays)'), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asStruct();
  }

  /// Invokes org.freedesktop.Secret.Item.SetSecret()
  Future<void> callSetSecret(List<DBusValue> secret, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.freedesktop.Secret.Item', 'SetSecret', [DBusStruct(secret)], replySignature: DBusSignature(''), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
  }
}
