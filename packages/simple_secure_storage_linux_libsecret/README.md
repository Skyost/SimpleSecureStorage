# simple_secure_storage_linux_libsecret

The **legacy libsecret-based Linux implementation** of
[`simple_secure_storage`](https://pub.dev/packages/simple_secure_storage), preserved
as an optional compatibility fallback.

This package restores the native C++ implementation from
[commit `1e2b0e9`](https://github.com/Skyost/SimpleSecureStorage/tree/1e2b0e9ef770673050d473fa518239763f4f031e/packages/simple_secure_storage_linux),
immediately before [PR #15](https://github.com/Skyost/SimpleSecureStorage/pull/15)
replaced it with a Dart implementation using the Secret Service D-Bus API directly.
It uses Flutter method channels and GNOME libsecret to access the keyring.

## Maintenance status

**This is a legacy, unmaintained package.** It is provided as-is for applications
that need to retain the previous Linux backend or encounter problems with the
replacement. No ongoing bug fixes, security fixes, or new features are promised.

For new applications and normal use, prefer the default
[`simple_secure_storage_linux`](https://pub.dev/packages/simple_secure_storage_linux)
implementation. Adding this fallback is optional; it is not included automatically
by `simple_secure_storage`.

## Usage

Add the latest releases of this package and `simple_secure_storage` as **direct
dependencies of your application** :

```sh
flutter pub add simple_secure_storage simple_secure_storage_linux_libsecret
```

Use the updated Linux implementation released alongside this fallback. Older
`simple_secure_storage_linux` releases (through `0.2.5`) have an incorrect
federated plugin declaration and may register their native plugin alongside this
one. The registration fix is included in this repository with the new package.

Flutter selects this explicit Linux implementation instead of the default one.
Keep using the public `simple_secure_storage` API; no manual registration or
additional Dart import is needed :

```dart
import 'package:flutter/widgets.dart';
import 'package:simple_secure_storage/simple_secure_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SimpleSecureStorage.initialize(
    const InitializationOptions(
      appName: 'My App',
      namespace: 'com.example',
    ),
  );

  await SimpleSecureStorage.write('token', 'example');
  final token = await SimpleSecureStorage.read('token');
  // Use the value in your application, then call runApp(...).
}
```

Initialize once before accessing storage. This package only implements Linux;
the other platforms keep their usual implementations.

Do not also declare `simple_secure_storage_linux` (or another Linux implementation)
as a direct dependency: Flutter requires a single explicit choice. The default
package may remain in the dependency graph through `simple_secure_storage`.
Remove the `simple_secure_storage_linux_libsecret` dependency to return to the
default implementation. After changing dependencies, run `flutter pub get` and
fully rebuild your Linux application; hot reload is not sufficient for native
plugin changes.

See the [example](example) for a runnable Linux application and integration tests.

## Linux requirements

In addition to the usual Flutter Linux build tools, the build machine needs
**libsecret 0.18.4 or later**, its development headers, and `pkg-config`.

On Debian/Ubuntu :

```sh
sudo apt install libsecret-1-dev pkg-config
```

On Fedora :

```sh
sudo dnf install libsecret-devel pkgconf-pkg-config
```

The native build also downloads nlohmann/json 3.12.0 from GitHub using CMake
FetchContent, so the first build needs network access.

At runtime, the application needs the libsecret shared library (for example,
`libsecret-1-0` on Debian/Ubuntu or `libsecret` on Fedora), a session D-Bus, and an
available Secret Service backend such as GNOME Keyring or a compatible KDE Wallet.
The keyring may prompt the user to unlock it. Distributing the application also
requires making libsecret available in the target system or package runtime.

This package preserves the previous libsecret behavior; it does not add a
dedicated XDG Secret Portal implementation or guarantee support for every sandbox.

## Existing data and compatibility

The package name changes, but the storage identity does not. It retains :

* The `fr.skyost.SimpleSecureStorage` secret schema.
* The `data` attribute derived from `namespace` and `appName`, with spaces removed.
* The JSON key/value map stored in the keyring and the existing key-prefix behavior.
* The `fr.skyost.simple_secure_storage` method channel.

Keep the **same `appName`, `namespace`, and `prefix`** that your application used
previously. With the same keyring/backend and initialization options, existing
entries can be reused without copying or migrating them. Changing these options
can make existing values appear missing.

The direct D-Bus implementation uses the same schema and data format. Empty
stores written by this package use `{}`; legacy `null` stores are read as empty
maps. Renaming the package does not move data between keyrings, users, or libsecret
backends. In particular, data stored through a different sandbox/backend is not
automatically migrated.

The native implementation otherwise retains its historical behavior, including
synchronous libsecret calls and its keyring warmup workaround.
