import 'package:flutter/services.dart';
import 'package:simple_secure_storage/src/platform_interface.dart';

/// An implementation of [SimpleSecureStoragePlatform] that uses method channels.
class MethodChannelSimpleSecureStorage extends SimpleSecureStoragePlatform {
  /// The method channel used to interact with the native platform.
  final MethodChannel _methodChannel = const MethodChannel('fr.skyost.simple_secure_storage');

  @override
  Future<void> initialize({
    String? appName,
    String? namespace,
  }) =>
      _methodChannel.invokeMethod(
        'initialize',
        {
          if (appName != null) 'appName': appName,
          if (namespace != null) 'namespace': namespace,
        },
      );

  @override
  Future<bool> has(String key) async => (await _methodChannel.invokeMethod<bool>('has', _createArguments(key))) == true;

  @override
  Future<String?> read(String key) => _methodChannel.invokeMethod<String>('read', _createArguments(key));

  @override
  Future<void> write(String key, String value) => _methodChannel.invokeMethod('write', _createArguments(key, value));

  @override
  Future<void> delete(String key) => _methodChannel.invokeMethod('delete', _createArguments(key));

  @override
  Future<void> clear() => _methodChannel.invokeMethod('clear');

  /// Creates the arguments to send to the method channel.
  Map<String, String?> _createArguments(String key, [String? value]) => {
        'key': key,
        if (value != null) 'value': value,
      };
}
