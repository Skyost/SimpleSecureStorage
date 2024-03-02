/// Allows to configure the plugin initialization.
class InitializationOptions {
  /// Your app name.
  final String? appName;

  /// Your app namespace.
  final String? namespace;

  /// Prefix to automatically prepend to keys.
  /// This avoids conflicts on some platforms.
  final String? prefix;

  /// Creates a new initialization options instance.
  const InitializationOptions({
    this.appName,
    this.namespace,
    this.prefix = 'sss_',
  });
}
