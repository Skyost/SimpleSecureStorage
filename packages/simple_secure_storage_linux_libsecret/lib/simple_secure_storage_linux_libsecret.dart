import 'package:simple_secure_storage_platform_interface/simple_secure_storage_platform_interface.dart';

/// Legacy Linux implementation of [SimpleSecureStoragePlatform] using libsecret.
///
/// Preserved as an optional compatibility fallback. This implementation is not
/// actively maintained; prefer the default `simple_secure_storage_linux` package.
class SimpleSecureStorageLinuxLibsecret extends MethodChannelSimpleSecureStorage {
  /// Registers the libsecret method-channel implementation.
  static void registerWith() => SimpleSecureStoragePlatform.instance = SimpleSecureStorageLinuxLibsecret();
}
