## 0.1.0

- Restore the libsecret-based Linux backend from commit
  `1e2b0e9ef770673050d473fa518239763f4f031e` (before PR #15) as a separate,
  optional compatibility package.
- Register the native plugin and Dart method-channel implementation under the
  new package name while preserving the existing storage identity and key prefixes.
- Read legacy `null` stores as empty maps and write cleared stores as `{}` for
  compatibility with the direct D-Bus implementation.
- Document installation, native dependencies, existing-data compatibility, and
  the package's unmaintained status.
