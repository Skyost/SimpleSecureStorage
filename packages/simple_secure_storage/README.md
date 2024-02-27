# Simple Secure Storage

A simple and secure storage system for Flutter.

[![Maintained with Melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

## Motivations

I'm currently creating a TOTP app where secrets are encrypted using a master password and I need
a secure place to store the encryption / decryption key.

I knew that Flutter already had a such package called `flutter_secure_storage`. The only problem
is that it have open 100+ issues on Github, and that the author seems to be currently inactive on
Github.

That's why I've decided to create my own solution : **Simple Secure Storage** (_SSS_).

## Features

* Very _very_ simple and straightforward.
* Supports Android, iOS, macOS, Windows, Linux and web.
* Allows data to be cached (so that you can access it as fast as possible).
* Secure.
* Again, very simple.

## Getting started

### Minimum requirements

Simple Secure Storage uses :

* [Keychain](https://developer.apple.com/documentation/security/keychain_services) on Apple devices,
which is supported since _iOS 2.0_ and _macOS 10.6_.
* [`EncryptedSharedPreferences`](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences)
on Android, which supports a minimum SDK version of, at least, _21_.
* [`Crypt32`](https://learn.microsoft.com/fr-fr/windows/win32/api/dpapi/), which seems to be available
since Windows XP.
Note that, on Windows, everything is stored inside a file located at `%APPDATA%/Local/appName/namespace.dat`.
* [`libsecret`](https://wiki.gnome.org/Projects/Libsecret) on Linux.
* [`sembast_web`](https://pub.dev/packages/sembast_web) and [`webcrypto`](https://pub.dev/packages/webcrypto)
on web.

### Installation

Run the following command to add Simple Secure Storage to your Flutter project :

```shell
flutter pub add simple_secure_storage
```

Then, please make sure you follow the specific instructions for each platform you're targeting.

#### Android

Update the minimum SDK version in your `android/app/build.gradle` :

```xml
android {
    <!-- Other settings -->
    defaultConfig {
        minSdkVersion 18
        <!-- More settings -->
    }
    <!-- And more settings -->
}
```

Also, as stated on [Android Developers](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences),

> **WARNING:** The preference file should not be backed up with Auto Backup.
> When restoring the file it is likely the key used to encrypt it will no longer be present.
> You should exclude all `EncryptedSharedPreferences` from backup using [backup rules](https://developer.android.com/guide/topics/data/autobackup#IncludingFiles).

so either you completely disable auto backup, in your `AndroidManifest.xml` :

```xml
<application
     <!-- Some settings -->
    android:allowBackup="false"
    android:fullBackupContent="false">
```

or you only disable the backup of the encrypted shared preferences, which can be done
using [backup rules](https://developer.android.com/guide/topics/data/autobackup#IncludingFiles).
Note that the `sharedpref` path is the `namespace` key you're passing to the `initialize` method
of the plugin.

#### macOS

In Xcode, go to _Project settings_ > _Capabilities_ and enable _Keychain Sharing_
(see [this](https://stackoverflow.com/questions/65131018/how-can-i-enable-the-keychain-sharing-capability-in-xcode)).

#### Linux

Run the following command to install `libsecret-1-dev` :

```shell
sudo apt install -y libsecret-1-dev
```

### Code snippet

Here's simple example to get started.

```dart
// Initialize the plugin before using.
// Typically done in your `main()` method.
if (kIsWeb) {
  // To secure your data on Flutter web, we have to encrypt it using a password and salt.
  SimpleSecureStorageWeb.initializeWeb(keyPassword: 'password', encryptionSalt: 'salt');
}
await SimpleSecureStorage.initialize();

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

In the previous snippet, everything is read "on demand". Although in most implementations your data is
already cached in the memory on the platform side, you may want to access it without always using
`await`. To do so, use the class `CachedSimpleSecureStorage`.
It behaves exactly like the snippet above, except that you don't have to call `await SimpleSecureStorage.initialize()`,
but `await CachedSimpleSecureStorage.getInstance()`.

If you want a real example, feel free to check
[this one](https://github.com/Skyost/SimpleSecureStorage/tree/master/packages/simple_secure_storage/example)
on Github.

## Contributions

You have a lot of options to contribute to this project ! You can :

* [Fork it](https://github.com/Skyost/SimpleSecureStorage/fork) on Github.
* [Submit](https://github.com/Skyost/SimpleSecureStorage/issues/new/choose) a feature request or a bug report.
* [Donate](https://paypal.me/Skyost) to the developer.
