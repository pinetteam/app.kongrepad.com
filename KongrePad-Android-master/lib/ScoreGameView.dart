import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/AlertService.dart';
import 'package:kongrepad/Models/ScoreGame.dart';
import 'package:kongrepad/ScoreGamePointsView.dart';
import 'AppConstants.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreGameView extends StatefulWidget {
  const ScoreGameView({super.key});

  @override
  State<ScoreGameView> createState() => _ScoreGameViewState();
}

class _ScoreGameViewState extends State<ScoreGameView> {
  ScoreGame? scoreGame;
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
          _loading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  initState() {
    super.initState();
    getData();
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
                        color: Colors.white, // Circular background color
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          'assets/icon/chevron.left.svg',
                          color: AppConstants.backgroundBlue,
                          height: screenHeight * 0.03,
                        ),
                      ),
                    ),
                  ),
                  const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Doğaya can ver",
                          style: TextStyle(fontSize: 25, color: Colors.white),
                        )
                      ]),
                ],
              ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(screenWidth * 0.4),
                        ),
                        child: Container(
              width: screenHeight * 0.3,
              height: screenHeight * 0.3,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child:   Center(
                  child: Icon(
                    FontAwesomeIcons.qrcode,  // QR kod ikonu
                    size: 150,                 // İkon boyutu
                    color: Colors.green,       // İkon rengi
                  ),
                ),
              ),
                        ),
                      ),
                      Text("${scoreGame?.userTotalPoint} puan",
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
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                  const EdgeInsets.all(12),
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ScoreGamePointsView()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //todo kamera iconu koy
                  SvgPicture.asset(
                    'assets/icon/checklist.checked.svg',
                    color: Colors.white,
                    width: screenWidth * 0.03,
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
                        MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
                            child: const QRViewExample(),
                          ),
                        );
                      },
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //todo kamera iconu koy
                      SvgPicture.asset(
                        'assets/icon/chevron.right.svg',
                        color: Colors.white,
                        width: screenWidth * 0.03,
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
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  String? responseText;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
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
                  if (result != null)
                    Text('$responseText')
                  else
                    const Text('Scan a code'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        if (result != null) {
          SendQr(result!.code!);
        }
      });
    });
  }

  Future<void> SendQr(String code) async {
    await controller?.pauseCamera();
    final response = await http.post(
      Uri.parse('http://app.kongrepad.com/api/v1/score-game/0/point'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'code': code,
      }),
    );
    if (jsonDecode(response.body)['token'] != null) {
      setState(() {
        responseText = jsonDecode(response.body)['token'];
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseText!);
      AlertService().showAlertDialog(
        context,
        title: 'Başarılı',
        content: 'Qr Kod Başarıyla okutuldu.',
      );
    } else {
      AlertService().showAlertDialog(
        context,
        title: 'Uyarı',
        content: 'Yanlış Qr Kod Girdiniz!',
      );
      await controller?.resumeCamera();
    }
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
