A Linux implementation of [`simple_secure_storage`](https://pub.dev/packages/simple_secure_storage) using the XDG Desktop [Secret Portal API](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Secret.html) (`org.freedesktop.portal.Secret`).

## Usage

Register this implementation when the application should use the XDG Desktop
Secret Portal API (`org.freedesktop.portal.Secret`), such as when running in a
sandboxed environment (e.g., Flatpak or Snap).

```dart
import 'package:simple_secure_storage_linux_portal/simple_secure_storage_linux_portal.dart';

SimpleSecureStorageLinuxPortal.registerWith();
```

> [!IMPORTANT]
> `SimpleSecureStorageLinuxPortal.registerWith()` must be explicitly called. Simply adding the package as a dependency is not sufficient.

## Example

The following example registers this implementation when running in Flatpak.

```dart
import 'dart:io';

import 'package:simple_secure_storage_linux_portal/simple_secure_storage_linux_portal.dart';

if (Platform.isLinux) {
  final isFlatpak =
      Platform.environment.containsKey('FLATPAK_ID') ||
      Platform.environment['container'] == 'flatpak';

  if (isFlatpak) {
    SimpleSecureStorageLinuxPortal.registerWith();
  }
}
```

> [!TIP]
> This is only an example of when to register the implementation. Applications
may choose different conditions based on their environment or requirements.

## Implementation Details

The Secret Portal API [provides a unique master secret](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Secret.html#org-freedesktop-portal-secret-retrievesecret) for a sandboxed application.

Unlike the Secret Service API, it does not provide secure storage itself. Instead, applications can use the master secret to encrypt secrets and store them in a file, for example.

### File Path

The secrets are stored encrypted in [a file](https://pub.dev/packages/xdg_secret_portal_store#storage-format):

`$XDG_DATA_HOME/$APPLICATION_ID/secure_storage/secrets.json`.

### Cryptography

For [security details](https://pub.dev/packages/xdg_secret_portal_store_default#cryptography).

### Not interoperable with GNOME libsecret

This implementation cannot retrieve secrets stored by [GNOME libsecret](https://gitlab.gnome.org/GNOME/libsecret).

For more details, refer to [this section](https://pub.dev/packages/xdg_secret_portal_store#not-interoperable-with-gnome-libsecret).
