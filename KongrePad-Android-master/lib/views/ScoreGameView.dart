import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/Models/ScoreGame.dart';
import 'package:kongrepad/utils/app_constants.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ScoreGamePointsView.dart';

class ScoreGameView extends StatefulWidget {
  const ScoreGameView({super.key});

  @override
  State<ScoreGameView> createState() => _ScoreGameViewState();
}
ScoreGame? scoreGame;
class _ScoreGameViewState extends State<ScoreGameView> {

  bool _loading = true;

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/score-game');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final scoreGameJson = ScoreGameJSON.fromJson(jsonData);
        setState(() {
          scoreGame = scoreGameJson.data;
          _loading = false; // UI'nin güncellenmesi için _loading'i değiştir
        });
        debugPrint("API Response: ${response.body}");

        print("User Total Point: ${scoreGame?.userTotalPoint}");
        debugPrint("API Response: ${response.body}");

      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  initState() {
    super.initState();
    getData();
    print("User Total Point: ${scoreGame?.userTotalPoint}");

  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    return Scaffold(
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                height: screenHeight * 0.1,
                decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white,
                        width: 1.0,
                      ),
                    ),
                    color: AppConstants.backgroundBlue),
                child: Container(
                  width: screenWidth,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: screenHeight * 0.05,
                          width: screenHeight * 0.05,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                            Colors.white, // Circular background color
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: AppConstants.backgroundBlue,
                            size: screenHeight * 0.03,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Puan Topla",
                          style: TextStyle(
                              fontSize: 25, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: screenHeight * 0.3,
                height: screenHeight * 0.3,
                child: const Center(
                  child: Icon(
                    FontAwesomeIcons.qrcode,
                    size: 150,
                    color: Colors.green,
                  ),
                ),
              ),
              Text(
                  "${scoreGame?.userTotalPoint ?? 0} puan",
                  style: TextStyle(
                      color: AppConstants.scoreGameGreen,
                      fontSize: 35,
                      fontWeight: FontWeight.bold)),
              SizedBox(
                height: screenHeight * 0.18,
              ),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        AppConstants.scoreGameGreen),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.black),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape: MaterialStateProperty.all<
                        RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const ScoreGamePointsView()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.checklist_rtl,
                        color: Colors.white,
                        size: screenWidth * 0.03,
                      ),
                      SizedBox(
                        width: screenWidth * 0.01,
                      ),
                      const Text(
                        'Puan Geçmişim',
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )),
              SizedBox(
                height: screenHeight * 0.18,
              ),
              Container(
                width: screenWidth,
                height: screenHeight * 0.1,
                decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white,
                        width: 1.0,
                      ),
                    ),
                    color: AppConstants.backgroundBlue),
                child: Center(
                  child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            AppConstants.scoreGameGreen),
                        foregroundColor:
                        MaterialStateProperty.all<Color>(
                            Colors.white),
                        padding:
                        MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(12),
                        ),
                        shape: MaterialStateProperty.all<
                            RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              contentPadding: EdgeInsets.zero,
                              content: Container(
                                width: screenWidth * 0.9,
                                height: screenHeight * 0.9,
                                child: QRViewExample(
                                  onQrSuccess: (addedPoints) {
                                    setState(() {
                                      scoreGame?.userTotalPoint =
                                          (scoreGame?.userTotalPoint ??
                                              0) +
                                              addedPoints;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: screenWidth * 0.03,
                          ),
                          SizedBox(
                            width: screenWidth * 0.01,
                          ),
                          const Text(
                            'Kare Kodu Okut',
                            style: TextStyle(fontSize: 25),
                          ),
                        ],
                      )),
                ),
              ),
            ],
          ),
        ));
  }
}

class QRViewExample extends StatefulWidget {
  final Function(int) onQrSuccess;

  const QRViewExample({Key? key, required this.onQrSuccess}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  String? responseText;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (responseText != null && responseText!.isNotEmpty)
                    Text(responseText!)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = 200.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      controller.pauseCamera();
      sendQr(scanData.code);
    });
  }

  Future<void> sendQr(String? code) async {
    if (code == null || code.isEmpty) {
      setState(() {
        responseText = 'Geçersiz QR kod.';
      });
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://app.kongrepad.com/api/v1/score-game/0/point');

    // Daha önce okutulmuş QR kodlarını al
    List<String>? scannedCodes = prefs.getStringList('scannedCodes') ?? [];

    if (scannedCodes.contains(code)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text('Bu kodu daha önce okuttunuz!'),
          );
        },
      );

      // QR tarama ekranını 2 saniye sonra aç
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop();
        controller?.resumeCamera();
      });
      return;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{'code': code}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        int addedPoints = responseData['addedPoints'] ?? 0;

        // Puanları güncelle ve setState çağır
        setState(() {
          scoreGame?.userTotalPoint =
              (scoreGame?.userTotalPoint ?? 0) + addedPoints;
        });

        // Taratılan kodu listeye ekle ve kaydet
        scannedCodes.add(code);
        prefs.setStringList('scannedCodes', scannedCodes);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(
                'Başarılı! $addedPoints puan eklendi. Toplam puan: ${scoreGame?.userTotalPoint}.',
              ),
            );
          },
        );

        // Popup'ı kapat ve QR ekranını yeniden başlat
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        });
      } else {
        setState(() {
          responseText = 'Yanlış QR kod girdiniz.';
        });
      }
    } catch (e) {
      setState(() {
        responseText = 'Bir hata oluştu: $e';
      });
    }
  }



  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
