import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_reader_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _qrText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_qrText != null)
              Text(
                _qrText!,
                style: Theme.of(context).textTheme.headline6,
              ),
            ElevatedButton(onPressed: _scan, child: const Text('Scan QR Code')),
          ],
        ),
      ),
    );
  }

  void _scan() async {
    final value = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRCodeReaderUI(),
      ),
    );

    setState(() {
      _qrText = value;
    });
  }
}
