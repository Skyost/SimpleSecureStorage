# Simple Secure Storage

A simple and secure storage system for Flutter. Supports Android, iOS, macOS, Windows and web !

[![Pub Likes](https://img.shields.io/pub/likes/simple_secure_storage?style=flat-square)](https://pub.dev/packages/simple_secure_storage/score)
[![Pub Points](https://img.shields.io/pub/points/simple_secure_storage?style=flat-square)](https://pub.dev/packages/simple_secure_storage/score)
[![Maintained with Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

## Motivations

I'm currently creating a TOTP app in which secrets are encrypted with a master password, and I need
a secure place to store the encryption/decryption key.

That's why I decided to create my own solution : **Simple Secure Storage** (_SSS_).

## Features

* Very _very_ simple and straightforward.
* Supports Android, iOS, macOS, Windows, Linux, and the web.
* Supports caching data for faster access.
* Secure.
* Again, very simple.

## Getting started

### Minimum requirements

Simple Secure Storage uses :

* [Keychain](https://developer.apple.com/documentation/security/keychain_services) on Apple devices,
which has been supported since _iOS 2.0_ and _macOS 10.6_.
* [`EncryptedSharedPreferences`](https://github.com/ed-george/encrypted-shared-preferences)
on Android, which requires a minimum SDK version of _21_.
* [`wincred.h`](https://learn.microsoft.com/en-us/windows/win32/api/wincred/) on Windows, which seems to
be available since _Windows XP_.
* An [`org.freedesktop.secrets`](https://specifications.freedesktop.org/secret-service/latest-single)
service implementation on Linux. A _secret service_ must be available (`gnome_keyring` is commonly installed).
* [`sembast_web`](https://pub.dev/packages/sembast_web) and [`cipherlib`](https://pub.dev/packages/cipherlib)
on the web.

### Installation

Run the following command to add Simple Secure Storage to your Flutter project :

```shell
flutter pub add simple_secure_storage
```

Then follow the instructions for each platform you target.

#### Android

As stated on [Android Developers](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences),

> [!WARNING]
> The preference file should not be backed up with Auto Backup.
> When restoring the file it is likely the key used to encrypt it will no longer be present.
> You should exclude all `EncryptedSharedPreferences` from backup using [backup rules](https://developer.android.com/guide/topics/data/autobackup#IncludingFiles).

Either disable Auto Backup entirely in your `AndroidManifest.xml` :

```xml
<application
     <!-- Some settings -->
    android:allowBackup="false"
    android:fullBackupContent="false">
```

or exclude only the encrypted shared preferences using
[backup rules](https://developer.android.com/guide/topics/data/autobackup#IncludingFiles).
The `sharedpref` path is the `namespace` value passed to the plugin's `initialize` method.

#### macOS

In Xcode, go to _Project settings_ > _Capabilities_ and enable _Keychain Sharing_
(see [this](https://stackoverflow.com/questions/65131018/how-can-i-enable-the-keychain-sharing-capability-in-xcode)).

#### Linux

These requirements are typically already satisfied by default on most desktop environments.

* D-Bus support.
* A running Secret Service implementation (such as GNOME Keyring, KDE Wallet, or another implementation providing the `org.freedesktop.secrets` D-Bus service).

> [!TIP]
> Starting from `0.3.0`, installing GNOME libsecret is no longer required. The Linux implementation uses the Secret Service D-Bus API directly.

### Code snippet

Here's a simple example to get started.

```dart
// Initialize the plugin before using it, typically in your `main()` method.
// You can provide a namespace and application name through `InitializationOptions`.
if (kIsWeb) {
  // To secure your data on Flutter web, we have to encrypt it using a password and a salt.
  await SimpleSecureStorage.initialize(WebInitializationOptions(keyPassword: 'password', encryptionSalt: 'salt'));
} else {
  await SimpleSecureStorage.initialize(); // You can also pass `InitializationOptions` here.
}

// Write a value.
await SimpleSecureStorage.write('key', 'value');

// Check if a value exists.
print(await SimpleSecureStorage.has('key')); // Will print "true".

// Read a value.
print(await SimpleSecureStorage.read('key')); // Will print "value".

// Remove a value.
await SimpleSecureStorage.delete('key');

// Clear everything.
await SimpleSecureStorage.clear();
```

In the previous snippet, everything is being read "on demand". You may want to access your data
without always having to write `await`. To do so, use the class `CachedSimpleSecureStorage`.
It behaves exactly like the snippet above, except you call `await CachedSimpleSecureStorage.getInstance()`
instead of `await SimpleSecureStorage.initialize()`.

If you want a more complete example, feel free to check and run
[this one](https://github.com/Skyost/SimpleSecureStorage/tree/master/packages/simple_secure_storage/example),
which is available on GitHub. To run the example app on Apple platforms (iOS and macOS),
configure the development team in the project settings.

## Contributions

There are several ways to contribute to this project :

* [Fork it](https://github.com/Skyost/SimpleSecureStorage/fork) on Github.
* [Submit](https://github.com/Skyost/SimpleSecureStorage/issues/new/choose) a feature request or a bug report.
* [Donate](https://paypal.me/Skyost) to the developer.
