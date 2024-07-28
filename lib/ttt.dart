import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QrViewState();
}

class _QrViewState extends State<QrView> with SingleTickerProviderStateMixin {
  MobileScannerController controller = MobileScannerController();
  List<String> scannedData = [];
  final AudioPlayer audioPlayer = AudioPlayer();
  bool _isDialogShowing = false;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _startTimer();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    controller.dispose();
    audioPlayer.dispose();
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
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

  void _startTimer() {
    _timer = Timer(Duration(hours: 1), () {
      setState(() {
        scannedData.clear();
      });
    });
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

  Future<Map<String, dynamic>?> _fetchDataFromFirebase(String url) async {
    try {
      // استخراج الجزء المهم من الرابط
      String baseUrl = 'https://panel-control-company-zaher.web.app/';
      if (!url.startsWith(baseUrl)) {
        throw FormatException('Invalid URL format');
      }

      // إزالة الجزء الأول من الرابط
      String remainingPath = url.substring(baseUrl.length);

      // استخراج المجلد الشهري ومعرف المنتج من المسار المتبقي
      String monthFolder = remainingPath.substring(0, 7); // السبع خانات الأولى
      String productId = remainingPath.substring(8); // ما تبقى هو معرف المنتج

      // استعلام البيانات من Firestore
      DocumentSnapshot document = await FirebaseFirestore.instance
          .collection('products') // اسم المجموعة في Firestore
          .doc('productsForAllMonths') // اسم المجلد الذي يحتوي على جميع الشهور
          .collection(monthFolder) // اسم المجلد الشهر
          .doc(productId) // معرف المستند الذي نريد عرضه
          .get();

      return document.exists ? document.data() as Map<String, dynamic>? : null;
    } catch (e) {
      print('Error fetching data: $e');
      return null;
    }
  }

  void _showDetailsDialog(String code, Map<String, dynamic>? data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Details for $code'),
          content: data != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: data.entries.map((entry) {
                    return ListTile(
                      title: Text('${entry.key}: ${entry.value}'),
                    );
                  }).toList(),
                )
              : Text('No data found for this code.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
        title: const Text('QR Scanner'),
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
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  allowDuplicates: true,
                  onDetect: (barcode, args) async {
                    if (barcode.rawValue == null) {
                      return;
                    }
                    final String code = barcode.rawValue!;
                    final BarcodeType type = barcode.type;

                    if (!scannedData.contains(code)) {
                      if (code.contains(
                          'https://panel-control-company-zaher.web.app/')) {
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
                        await _playSound('assets/sound/beep.mp3');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Invalid code scanned and removed. رمز غير صالح تم مسحه ضوئيًا وإزالته.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        await Future.delayed(
                            Duration(seconds: 2)); // إضافة تأخير لمدة ٢ ثانية
                      }
                    } else {
                      _playSound('assets/sound/beep.mp3');
                      await Future.delayed(
                          Duration(seconds: 5)); // إضافة تأخير لمدة ٢ ثانية
                      _showDuplicateDialog(code);
                    }
                  },
                ),
                CustomPaint(
                  painter: ScannerOverlay(),
                  child: Container(),
                ),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      top: MediaQuery.of(context).size.height * 0.3 +
                          (_animation.value *
                              (MediaQuery.of(context).size.height * 0.4)),
                      left: MediaQuery.of(context).size.width * 0.1,
                      right: MediaQuery.of(context).size.width * 0.1,
                      child: Container(
                        height: 2.0,
                        color: Colors.red,
                      ),
                    );
                  },
                ),
              ],
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
                  final code = scannedData[index];
                  final displayCode = code.substring(
                      'https://panel-control-company-zaher.web.app/'.length +
                          7); // إزالة الرابط والسبع خانات الأولى
                  return ListTile(
                    title: Text(displayCode),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          scannedData.removeAt(index);
                        });
                      },
                    ),
                    onTap: () async {
                      final data = await _fetchDataFromFirebase(code);
                      _showDetailsDialog(displayCode, data);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final double cornerLength = 30.0;
    final double cornerOffset = 10.0;

    // Draw corners
    // Top-left
    canvas.drawLine(Offset(cornerOffset, cornerOffset),
        Offset(cornerOffset + cornerLength, cornerOffset), paint);
    canvas.drawLine(Offset(cornerOffset, cornerOffset),
        Offset(cornerOffset, cornerOffset + cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - cornerOffset, cornerOffset),
        Offset(size.width - cornerOffset - cornerLength, cornerOffset), paint);
    canvas.drawLine(Offset(size.width - cornerOffset, cornerOffset),
        Offset(size.width - cornerOffset, cornerOffset + cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(cornerOffset, size.height - cornerOffset),
        Offset(cornerOffset + cornerLength, size.height - cornerOffset), paint);
    canvas.drawLine(Offset(cornerOffset, size.height - cornerOffset),
        Offset(cornerOffset, size.height - cornerOffset - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(size.width - cornerOffset, size.height - cornerOffset),
        Offset(size.width - cornerOffset - cornerLength,
            size.height - cornerOffset),
        paint);
    canvas.drawLine(
        Offset(size.width - cornerOffset, size.height - cornerOffset),
        Offset(size.width - cornerOffset,
            size.height - cornerOffset - cornerLength),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
