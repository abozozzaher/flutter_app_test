import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRViewExample()),
                );
              },
              child: const Text('Open QR Scanner'),
            ),
          ],
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  MobileScannerController controller = MobileScannerController();
  List<String> scannedData = [];
  final AudioPlayer audioPlayer = AudioPlayer();
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      if (await Permission.camera.request().isGranted) {
        print('Camera permission granted');
      }
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _playSound(String path) async {
    await audioPlayer.play(AssetSource(path));
  }

  void _showDuplicateDialog(String code) {
    if (_isDialogShowing) return; // التحقق من عدم إظهار مربع الحوار مسبقًا
    _isDialogShowing = true; // ضبط المتغير إلى true لإظهار مربع الحوار

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Duplicate Code'),
          content: Text('The code "$code" has already been scanned.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _isDialogShowing =
                    false; // إعادة ضبط المتغير إلى false عند إغلاق مربع الحوار
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scan1ner'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: MobileScanner(
              controller: controller,
              allowDuplicates: true,
              onDetect: (barcode, args) async {
                if (barcode.rawValue == null) {
                  return;
                }
                final String code = barcode.rawValue!;
                final BarcodeType type = barcode.type;

                if (!scannedData.contains(code)) {
                  setState(() {
                    scannedData.add(code);
                  });
                  _playSound('assets/sound/scanner-beep.mp3');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Scanned: $code'),
                      backgroundColor: type == BarcodeFormat.qrCode
                          ? Colors.blueGrey
                          : Colors.green,
                    ),
                  );
                } else {
                  _playSound('assets/sound/beep.mp3');
                  _showDuplicateDialog(code);
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: scannedData.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(scannedData[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    audioPlayer.dispose();
    super.dispose();
  }
}
