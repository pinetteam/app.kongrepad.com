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

      // API dokümanına göre doğru URL
      final response = await http.post(
        Uri.parse('https://api.kongrepad.com/api/v1/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'username': code,
          // Eğer password gerekiyorsa ekle:
          // 'password': code, // veya başka bir değer
        }),
      );

      print('API yanıtı alındı: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('API yanıtı içeriği: $responseBody');

        // API dokümanına göre token data içinde
        if (responseBody['success'] == true &&
            responseBody['data'] != null &&
            responseBody['data']['token'] != null) {

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseBody['data']['token']);

          // Participant bilgilerini de kaydet (opsiyonel)
          if (responseBody['data']['participant'] != null) {
            await prefs.setString('participant',
                jsonEncode(responseBody['data']['participant']));
          }

          Navigator.pushNamed(context, '/main');
        } else {
          print('Token bulunamadı!');
          AlertService().showAlertDialog(
              context,
              title: 'Hata',
              content: 'Yanlış QR kod girdiniz!'
          );
          await controller?.resumeCamera();
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized - Yanlış kimlik bilgileri');
        AlertService().showAlertDialog(
            context,
            title: 'Hata',
            content: 'Geçersiz QR kod!'
        );
        await controller?.resumeCamera();
      } else {
        print('API hata kodu: ${response.statusCode}');
        AlertService().showAlertDialog(
            context,
            title: 'Hata',
            content: 'Sunucuya bağlanılamadı! (${response.statusCode})'
        );
        await controller?.resumeCamera();
      }
    } catch (e) {
      print('API çağrısı sırasında hata: $e');
      AlertService().showAlertDialog(
          context,
          title: 'Hata',
          content: 'Bağlantı hatası: $e'
      );
      await controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}