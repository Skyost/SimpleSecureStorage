import 'package:simple_secure_storage/src/implementations/method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The platform interface to interact with.
abstract class SimpleSecureStoragePlatform extends PlatformInterface {
  /// The token instance.
  static final Object _token = Object();

  /// The platform interface instance.
  static SimpleSecureStoragePlatform _instance = MethodChannelSimpleSecureStorage();

  /// Constructs a SimpleSecureStoragePlatform.
  SimpleSecureStoragePlatform()
      : super(
          token: _token,
        );

  /// The default instance of [SimpleSecureStoragePlatform] to use.
  ///
  /// Defaults to [MethodChannelSimpleSecureStorage].
  static SimpleSecureStoragePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SimpleSecureStoragePlatform] when
  /// they register themselves.
  static set instance(SimpleSecureStoragePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes the plugin.
  Future<void> initialize({
    String? appName,
    String? namespace,
  }) =>
      Future.value();

  /// Returns whether the secure storage has the given [key].
  Future<bool> has(String key);

  /// Returns the value of the given [key].
  Future<String?> read(String key);

  /// Writes the [value] so that it corresponds to the [key].
  Future<void> write(String key, String value);

  /// Deletes the value associated to the given [key].
  Future<void> delete(String key);

  /// Clears all values.
  Future<void> clear();
}
