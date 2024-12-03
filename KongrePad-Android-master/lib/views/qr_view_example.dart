import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alert_service.dart';

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300.0,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      try {
        setState(() {
          result = scanData;
        });
        if (result != null) {
          await controller.pauseCamera();
          print('Taranan QR kod: ${result!.code}');
          await _login(result!.code!);
        }
      } catch (e) {
        print('QR tarama sırasında hata: $e');
        await controller.resumeCamera();
      }
    });
  }

  Future<void> _login(String code) async {
    try {
      print('API çağrısı başlatılıyor...');
      final response = await http.post(
        Uri.parse('http://app.kongrepad.com/api/v1/auth/login/participant'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{'username': code}),
      );

      print('API yanıtı alındı: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('API yanıtı içeriği: $responseBody');

        if (responseBody['token'] != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseBody['token']);
          Navigator.pushNamed(context, '/main');
        } else {
          print('Token bulunamadı!');
          AlertService().showAlertDialog(context, title: 'Hata', content: 'Yanlış QR kod girdiniz!');
          await controller?.resumeCamera();
        }
      } else {
        print('API hata kodu: ${response.statusCode}');
        AlertService().showAlertDialog(context, title: 'Hata', content: 'Sunucuya bağlanılamadı!');
        await controller?.resumeCamera();
      }
    } catch (e) {
      print('API çağrısı sırasında hata: $e');
      AlertService().showAlertDialog(context, title: 'Hata', content: 'Bir hata oluştu: $e');
      await controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
