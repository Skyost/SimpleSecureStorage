import 'dart:async';

/// A collection of static functions to throttle calls to a target function.
class Throttle {
  /// Map of functions currently being throttled.
  static Map<Function, _ThrottleTarget> _throttled = <Function, _ThrottleTarget>{};

  /// Clears the [target] from the functions to throttle.
  static bool clear(Function target) {
    if (_throttled.containsKey(target)) {
      _throttled.remove(target);
      return true;
    }

    return false;
  }

  /// Calls [duration] with a timeout specified in milliseconds.
  static bool milliseconds(
    int timeoutMs,
    Function target, {
    List<dynamic> positionalArguments = const [],
    Map<Symbol, dynamic> namedArguments = const {},
    bool leading = true,
    bool trailing = false,
  }) =>
      duration(Duration(milliseconds: timeoutMs), target, positionalArguments: positionalArguments, namedArguments: namedArguments, leading: leading, trailing: trailing);

  /// Calls [duration] with a timeout specified in seconds.
  static bool seconds(
    int timeoutSeconds,
    Function target, {
    List<dynamic> positionalArguments = const [],
    Map<Symbol, dynamic> namedArguments = const {},
    bool leading = true,
    bool trailing = false,
  }) =>
      duration(Duration(seconds: timeoutSeconds), target, positionalArguments: positionalArguments, namedArguments: namedArguments, leading: leading, trailing: trailing);

  /// Calls [target] based on leading/trailing configuration and prevents subsequent calls until [timeout] duration.
  static bool duration(
    Duration timeout,
    Function target, {
    List<dynamic> positionalArguments = const [],
    Map<Symbol, dynamic> namedArguments = const {},
    bool leading = true,
    bool trailing = false,
  }) {
    if (_throttled.containsKey(target)) {
      if (trailing) {
        _throttled[target]!.updateTrailingCall(positionalArguments, namedArguments);
      }
      return false;
    }

    if (leading) {
      Function.apply(target, positionalArguments, namedArguments);
    }

    final _ThrottleTarget throttleTarget = _ThrottleTarget(target, positionalArguments, namedArguments, trailing);
    _throttled[target] = throttleTarget;

    Timer(timeout, () {
      if (trailing) {
        final target = _throttled[throttleTarget.target]!;
        Function.apply(target.target, target.latestPositionalArguments, target.latestNamedArguments);
      }
      _throttled.remove(throttleTarget.target);
    });

    return leading;
  }
}

/// A throttle target.
class _ThrottleTarget {
  /// The function to call.
  final Function target;

  /// The positional arguments.
  List<dynamic> positionalArguments;

  /// The named arguments.
  Map<Symbol, dynamic> namedArguments;

  /// Whether this function has a trailing call.
  final bool hasTrailing;

  /// The latest positional arguments.
  List<dynamic> latestPositionalArguments;

  /// The latest named arguments.
  Map<Symbol, dynamic> latestNamedArguments;

  /// Creates a new throttle target instance.
  _ThrottleTarget(this.target, this.positionalArguments, this.namedArguments, this.hasTrailing)
      : latestPositionalArguments = positionalArguments,
        latestNamedArguments = namedArguments;

  /// Updates the trailing call.
  void updateTrailingCall(List<dynamic> newPositionalArgs, Map<Symbol, dynamic> newNamedArgs) {
    if (hasTrailing) {
      latestPositionalArguments = newPositionalArgs;
      latestNamedArguments = newNamedArgs;
    }
  }
}
