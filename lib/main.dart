import 'package:flutter/material.dart';
import 'package:flutter_app/ttt.dart';

import 'qr_view.dart';
import 'scan_file.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRViewExample()),
                );
              },
              label: const Text('Open QR Scanner'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.code),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QrView()),
                );
              },
              label: const Text('Open QR Scanner'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.scanner_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ScannQRViewaaaExample()),
                );
              },
              label: const Text('Scanner QR file'),
            ),
          ],
        ),
      ),
    );
  }
}
