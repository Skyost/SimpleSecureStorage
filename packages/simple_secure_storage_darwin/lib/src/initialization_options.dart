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
    this.accessibility = DarwinAccessibility.whenUnlocked,
  });

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
