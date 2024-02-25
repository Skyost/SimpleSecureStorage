import 'package:flutter/material.dart';
import 'dart:async';

import 'package:simple_secure_storage/simple_secure_storage.dart';

/// Hello world !
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SimpleSecureStorage.initialize();
  runApp(const SimpleSecureStorageExampleApp());
}

/// The main app widget.
class SimpleSecureStorageExampleApp extends StatefulWidget {
  /// Creates a new widget instance.
  const SimpleSecureStorageExampleApp({
    super.key,
  });

  @override
  State<SimpleSecureStorageExampleApp> createState() => _SimpleSecureStorageExampleAppState();
}

/// The widget state.
class _SimpleSecureStorageExampleAppState extends State<SimpleSecureStorageExampleApp> {
  /// The increment count.
  int count = 0;

  /// Whether the storage has the "count" key.
  bool has = false;

  @override
  void initState() {
    super.initState();
    refreshIncrementCount();
  }

  /// Platform messages are asynchronous, so we initialize in an async method.
  Future<void> refreshIncrementCount() async {
    bool has = await SimpleSecureStorage.has('count');
    if (!has) {
      if (mounted) {
        setState(() {
          this.has = has;
          this.count = 0;
        });
      }
      return;
    }
    int count = int.parse((await SimpleSecureStorage.read('count'))!);
    if (mounted) {
      setState(() {
        this.count = count;
        this.has = has;
      });
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('SimpleSecureStorage example app'),
          ),
          body: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('Increment count : ${has ? count : 'no yet incremented !'}'),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () async {
                      int count = this.count + 1;
                      await SimpleSecureStorage.write('count', count.toString());
                      await refreshIncrementCount();
                    },
                    child: const Text('Increment and save'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () async {
                      await SimpleSecureStorage.delete('count');
                      await refreshIncrementCount();
                    },
                    child: const Text('Delete'),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await SimpleSecureStorage.clear();
                    await refreshIncrementCount();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
      );
}
