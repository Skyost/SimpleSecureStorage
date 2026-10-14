import 'package:flutter/material.dart';
import 'package:simple_secure_storage/simple_secure_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SimpleSecureStorage.initialize(
    const InitializationOptions(
      appName: 'Libsecret Example',
      namespace: 'fr.skyost.simple_secure_storage.example',
    ),
  );
  runApp(const MaterialApp(home: StorageExample()));
}

class StorageExample extends StatefulWidget {
  const StorageExample({super.key});

  @override
  State<StorageExample> createState() => _StorageExampleState();
}

class _StorageExampleState extends State<StorageExample> {
  String _message = 'Save a sample value, then read it from the keyring.';
  bool _busy = false;

  Future<void> _run(Future<String> Function() operation) async {
    setState(() => _busy = true);
    String message;
    try {
      message = await operation();
    } catch (error) {
      message = 'Keyring operation failed: $error';
    }
    if (!mounted) return;
    setState(() {
      _message = message;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Legacy libsecret example')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Uses the optional, unmaintained libsecret backend.'),
          const SizedBox(height: 24),
          Text(_message),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await SimpleSecureStorage.write('sample', 'Hello 🔐');
                        return 'Sample saved.';
                      }),
                child: const Text('Save sample'),
              ),
              ElevatedButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        return await SimpleSecureStorage.read('sample') ??
                            'No sample saved.';
                      }),
                child: const Text('Read sample'),
              ),
              ElevatedButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await SimpleSecureStorage.delete('sample');
                        return 'Sample deleted.';
                      }),
                child: const Text('Delete sample'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
