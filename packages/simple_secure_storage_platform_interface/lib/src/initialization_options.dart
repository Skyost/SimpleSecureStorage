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

  @override
  bool operator ==(Object other) {
    if (other is! InitializationOptions) {
      return super == other;
    }
    return other.appName == appName && other.namespace == namespace;
  }

  @override
  int get hashCode => Object.hash(appName, namespace, prefix);

  /// Copies this instance with the given parameters.
  InitializationOptions copyWith({
    String? appName,
    String? namespace,
    String? prefix,
  }) => InitializationOptions(
    appName: appName ?? this.appName,
    namespace: namespace ?? this.namespace,
    prefix: prefix ?? this.prefix,
  );

  /// Serializes the options to a map.
  Map<String, dynamic> toMap() => {
    'appName': ?appName,
    'namespace': ?namespace,
  };

  @override
  String toString() => toMap().toString();
}
