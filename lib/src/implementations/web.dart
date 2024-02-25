// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:simple_secure_storage/src/platform_interface.dart';

/// A web implementation of the SimpleSecureStoragePlatform of the SimpleSecureStorage plugin.
class SimpleSecureStorageWeb extends SimpleSecureStoragePlatform {
  /// Constructs a SimpleSecureStorageWeb.
  SimpleSecureStorageWeb();

  /// Registers this implementation.
  static void registerWith(Registrar registrar) {
    SimpleSecureStoragePlatform.instance = SimpleSecureStorageWeb();
  }

  @override
  Future<bool> has(String key) {
    // TODO: implement has
    throw UnimplementedError();
  }

  @override
  Future<String?> read(String key) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  Future<void> write(String key, String value) {
    // TODO: implement write
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String key) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<void> clear() {
    // TODO: implement clear
    throw UnimplementedError();
  }
}
