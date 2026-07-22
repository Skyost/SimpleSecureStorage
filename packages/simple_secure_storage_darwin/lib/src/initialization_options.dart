import 'package:flutter/foundation.dart';
import 'package:simple_secure_storage_platform_interface/simple_secure_storage_platform_interface.dart';

/// Allows to pass specific options to the Darwin implementation.
class DarwinInitializationOptions extends InitializationOptions {
  /// The accessibility of the keychain items.
  final DarwinAccessibility accessibility;

  /// Creates a new initialization options instance.
  const DarwinInitializationOptions({
    super.appName,
    super.namespace,
    super.prefix,
    DarwinAccessibility? accessibility,
  }) : accessibility = accessibility ?? DarwinAccessibility.whenUnlocked;

  @override
  bool operator ==(Object other) {
    if (other is! DarwinInitializationOptions) {
      return super == other;
    }
    return appName == other.appName && namespace == other.namespace && accessibility == other.accessibility;
  }

  @override
  int get hashCode => Object.hash(appName, namespace, accessibility);

  @override
  DarwinInitializationOptions copyWith({
    String? appName,
    String? namespace,
    String? prefix,
    DarwinAccessibility? accessibility,
  }) => DarwinInitializationOptions(
    appName: appName ?? this.appName,
    namespace: namespace ?? this.namespace,
    prefix: prefix ?? this.prefix,
    accessibility: accessibility ?? this.accessibility,
  );

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'accessibility': accessibility.name,
  };
}

/// Defines the accessibility of the keychain items.
enum DarwinAccessibility {
  /// The data in the keychain item can be accessed only while the device is unlocked by the user.
  ///
  /// This is the default value.
  whenUnlocked,

  /// The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
  ///
  /// After the first unlock, the data remains accessible until the next restart.
  /// This is recommended for items that need to be accessed by background applications.
  afterFirstUnlock,

  /// The data in the keychain item can be accessed only while the device is unlocked by the user.
  ///
  /// This is recommended for items that need to be accessed only while the application is in the foreground.
  whenUnlockedThisDeviceOnly,

  /// The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
  ///
  /// After the first unlock, the data remains accessible until the next restart.
  /// This is recommended for items that need to be accessed by background applications.
  afterFirstUnlockThisDeviceOnly,
}

/// Allows to configure the plugin initialization for Darwin platforms (ie. iOS and macOS).
extension ConfigureForDarwin on InitializationOptions {
  /// Configures the plugin initialization for Darwin platforms (ie. iOS and macOS).
  InitializationOptions configureForDarwin({
    String? keyPassword,
    String? encryptionSalt,
    DarwinAccessibility? accessibility,
  }) => !kIsWeb && (defaultTargetPlatform == .iOS || defaultTargetPlatform == .macOS)
      ? DarwinInitializationOptions(
          appName: appName,
          namespace: namespace,
          prefix: prefix,
          accessibility: accessibility,
        )
      : copyWith();
}
