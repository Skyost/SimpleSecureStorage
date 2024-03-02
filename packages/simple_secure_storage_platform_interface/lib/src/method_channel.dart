import 'package:flutter/services.dart';
import 'package:simple_secure_storage_platform_interface/src/platform_interface.dart';

/// An implementation of [SimpleSecureStoragePlatform] that uses method channels.
class MethodChannelSimpleSecureStorage extends SimpleSecureStoragePlatform {
  /// The method channel used to interact with the native platform.
  final MethodChannel _methodChannel = const MethodChannel('fr.skyost.simple_secure_storage');

  /// The prefix to prepend to keys.
  late final String _prefix;

  @override
  Future<void> initialize(InitializationOptions options) async {
    _prefix = options.prefix ?? '';
    await _methodChannel.invokeMethod(
      'initialize',
      {
        if (options.appName != null) 'appName': options.appName,
        if (options.namespace != null) 'namespace': options.namespace,
      },
    );
  }

  @override
  Future<bool> has(String key) async => (await _methodChannel.invokeMethod<bool>('has', _createArguments(key))) == true;

  @override
  Future<String?> read(String key) => _methodChannel.invokeMethod<String>('read', _createArguments(key));

  @override
  Future<Map<String, String>> list() async {
    Map callResult = (await _methodChannel.invokeMethod<Map>('list')) ?? {};
    if (_prefix.isEmpty) {
      return callResult.cast<String, String>();
    }
    return callResult.map<String, String>((key, value) => MapEntry(key.substring(_prefix.length), value));
  }

  @override
  Future<void> write(String key, String value) => _methodChannel.invokeMethod('write', _createArguments(key, value));

  @override
  Future<void> delete(String key) => _methodChannel.invokeMethod('delete', _createArguments(key));

  @override
  Future<void> clear() => _methodChannel.invokeMethod('clear');

  /// Creates the arguments to send to the method channel.
  Map<String, String?> _createArguments(String key, [String? value]) => {
        'key': _prefix + key,
        if (value != null) 'value': value,
      };
}
