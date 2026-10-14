# Legacy libsecret example

This Linux application selects `simple_secure_storage_linux_libsecret` by adding
it as a direct dependency alongside `simple_secure_storage`. The Dart code keeps
using the usual public storage API.

Install the native dependencies described in the [package README](../README.md),
then run from this directory:

```sh
flutter pub get
flutter run -d linux
```

The example uses its own app name and namespace. It only reads or writes its
sample key; it does not clear the keyring.

## Integration tests

With a running Secret Service and an unlocked keyring in your desktop session:

```sh
flutter test integration_test/libsecret_test.dart -d linux
```

The tests verify automatic plugin selection, native CRUD operations, prefixes,
and compatibility with the direct D-Bus JSON format, including legacy empty
stores. Each run uses a unique storage identifier and removes its test entry
afterwards. The inherited libsecret warmup workaround also writes the historical
`SimpleSecureStorage Control` dummy entry.
