import 'package:simple_secure_storage/simple_secure_storage.dart';
import 'package:test/test.dart';

typedef Storage = SimpleSecureStorage;

/// Integration tests verifying the public behavior of [SimpleSecureStorage]
/// against a real secure storage implementation.
///
/// Requires a running Secret Service implementation on Linux.
///
/// Run with:
///   flutter test integration_test/integration_test.dart
void main() {
  setUp(() async {
    await Storage.initialize();
    await Storage.clear();
  });

  tearDownAll(() async {
    await Storage.clear();
  });

  test('writes and reads a value', () async {
    await Storage.write('username', 'alice');

    expect(await Storage.read('username'), 'alice');
  });

  test('reading a missing key returns null', () async {
    expect(await Storage.read('missing'), isNull);
  });

  test('has() reports whether a key exists', () async {
    expect(await Storage.has('username'), isFalse);

    await Storage.write('username', 'alice');
    expect(await Storage.has('username'), isTrue);

    await Storage.delete('username');
    expect(await Storage.has('username'), isFalse);
  });

  test('has() returns false after clear()', () async {
    await Storage.write('username', 'alice');

    await Storage.clear();

    expect(await Storage.has('username'), isFalse);
  });

  test('has() remains true when a value is replaced', () async {
    await Storage.write('username', 'alice');
    await Storage.write('username', 'bob');

    expect(await Storage.has('username'), isTrue);
  });

  test('list() returns all stored key-value pairs', () async {
    await Storage.write('username', 'alice');
    await Storage.write('password', 'secret');

    expect(await Storage.list(), {
      'username': 'alice',
      'password': 'secret',
    });
  });

  test('writing multiple values does not lose existing values', () async {
    await Storage.write('username', 'alice');

    await Storage.write('password', 'secret');

    expect(await Storage.list(), {
      'username': 'alice',
      'password': 'secret',
    });
  });

  test('writing an existing key replaces its value', () async {
    await Storage.write('username', 'alice');

    await Storage.write('username', 'bob');

    expect(await Storage.read('username'), 'bob');

    expect(await Storage.list(), {'username': 'bob'});
  });

  test('deletes a key without affecting other keys', () async {
    await Storage.write('username', 'alice');
    await Storage.write('password', 'secret');

    await Storage.delete('username');

    expect(await Storage.read('username'), isNull);
    expect(await Storage.read('password'), 'secret');
  });

  test('clear() removes all stored key-value pairs', () async {
    await Storage.write('username', 'alice');
    await Storage.write('password', 'secret');

    await Storage.clear();

    expect(await Storage.list(), isEmpty);
  });

  test('writes and reads empty strings', () async {
    await Storage.write('empty', '');

    expect(await Storage.read('empty'), '');
  });

  test('writes and reads UTF-8 values', () async {
    const value = 'pässwörd 🔐 مرحبا 世界';

    await Storage.write('secret', value);

    expect(await Storage.read('secret'), value);
  });

  test('writes and reads values containing JSON characters', () async {
    const value = r'{"key":"value","text":"quotes \" and \\ backslashes"}';

    await Storage.write('secret', value);

    expect(await Storage.read('secret'), value);
  });

  test('list() returns an empty map when no values are stored', () async {
    expect(await Storage.list(), isEmpty);
  });

  test('deleting a missing key succeeds', () async {
    await Storage.delete('missing');

    expect(await Storage.list(), isEmpty);
  });

  test('clear() succeeds when no values are stored', () async {
    await Storage.clear();

    expect(await Storage.list(), isEmpty);
  });

  test('deleting and rewriting a key works', () async {
    await Storage.write('username', 'alice');

    await Storage.delete('username');

    expect(await Storage.read('username'), isNull);

    await Storage.write('username', 'bob');

    expect(await Storage.read('username'), 'bob');
  });

  test('list() reflects updated values', () async {
    await Storage.write('username', 'alice');
    await Storage.write('password', 'old');

    await Storage.write('password', 'new');

    expect(await Storage.list(), {'username': 'alice', 'password': 'new'});
  });

  test('stored values can be read after a new initialization', () async {
    await Storage.write('username', 'alice');

    await Storage.initialize();

    expect(await Storage.read('username'), 'alice');
  });
}
