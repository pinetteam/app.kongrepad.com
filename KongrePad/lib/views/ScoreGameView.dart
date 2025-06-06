import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/ScoreGame.dart';
import '../utils/app_constants.dart';
import 'ScoreGamePointsView.dart';

class ScoreGameView extends StatefulWidget {
  const ScoreGameView({super.key});

  @override
  State<ScoreGameView> createState() => _ScoreGameViewState();
}

ScoreGame? scoreGame;

class _ScoreGameViewState extends State<ScoreGameView> {
  bool _loading = true;
  Map<String, dynamic>? myScores;
  List<dynamic>? scoreGames;
  int? selectedScoreGameId;

  Future<void> getData() async {
    print('🚀 getData() başladı');

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('🔑 Token: ${token != null ? "VAR (${token!.substring(0, 10)}...)" : "YOK"}');

    try {
      // 1. Önce tüm score games'leri al
      print('📋 Score games listesi alınıyor...');
      final scoreGamesUrl = Uri.parse('https://api.kongrepad.com/api/v1/score-games');
      final scoreGamesResponse = await http.get(
        scoreGamesUrl,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📋 Score Games Status: ${scoreGamesResponse.statusCode}');
      print('📋 Score Games Response: ${scoreGamesResponse.body}');

      if (scoreGamesResponse.statusCode == 200) {
        final scoreGamesData = jsonDecode(scoreGamesResponse.body);
        print('📋 Score Games Parsed: $scoreGamesData');

        if (scoreGamesData['success'] == true && scoreGamesData['data'] != null) {
          scoreGames = scoreGamesData['data'] as List;
          print('📋 ✅ ${scoreGames!.length} score game bulundu');

          // İlk score game'i seç (veya aktif olanı)
          if (scoreGames!.isNotEmpty) {
            selectedScoreGameId = scoreGames!.first['id'];
            print('📋 Selected Score Game ID: $selectedScoreGameId');
          }
        } else {
          print('📋 ❌ Score games success=false veya data=null');
        }
      } else {
        print('📋 ❌ Score games API failed: ${scoreGamesResponse.statusCode}');
      }

      // 2. My scores'u al
      print('🏆 My scores alınıyor...');
      final myScoresUrl = Uri.parse('https://api.kongrepad.com/api/v1/score-games/my-scores');
      final myScoresResponse = await http.get(
        myScoresUrl,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('🏆 My Scores Status: ${myScoresResponse.statusCode}');
      print('🏆 My Scores Response: ${myScoresResponse.body}');

      if (myScoresResponse.statusCode == 200) {
        final myScoresData = jsonDecode(myScoresResponse.body);
        print('🏆 My Scores Parsed: $myScoresData');

        if (myScoresData['success'] == true && myScoresData['data'] != null) {
          setState(() {
            myScores = myScoresData['data'];
            _loading = false;
          });

          print("🏆 ✅ My Scores Data: $myScores");
          print("🏆 Total Points: ${myScores?['total_points'] ?? 0}");
        } else {
          print('🏆 ❌ My scores success=false veya data=null');
          setState(() {
            _loading = false;
          });
        }
      } else {
        print('🏆 ❌ My scores API failed: ${myScoresResponse.statusCode}');
        setState(() {
          _loading = false;
        });
      }

      // 3. Eğer specific score game detayı gerekirse
      if (selectedScoreGameId != null) {
        print('🎮 Score game detayları alınıyor: $selectedScoreGameId');
        await getScoreGameDetails(selectedScoreGameId!);
      }

      print('✅ getData() tamamlandı');

    } catch (e, stackTrace) {
      print('❌ getData() HATA: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> getScoreGameDetails(int scoreGameId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse('https://api.kongrepad.com/api/v1/score-games/$scoreGameId');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          print("Score Game Details: ${jsonData['data']}");
          // Score game detaylarını kullanabilirsiniz
        }
      }
    } catch (e) {
      print('Score Game Details Error: $e');
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
                child: SizedBox(
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: AppConstants.backgroundBlue,
                            size: screenHeight * 0.03,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('points'),
                          style: const TextStyle(
                              fontSize: 25, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
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
              Text("${myScores?['total_points'] ?? 0} ",
                  style: const TextStyle(
                      color: AppConstants.scoreGameGreen,
                      fontSize: 35,
                      fontWeight: FontWeight.bold)),

              // Score Games Listesi (eğer birden fazla varsa)
              if (scoreGames != null && scoreGames!.length > 1)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppConstants.scoreGameGreen),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<int>(
                    value: selectedScoreGameId,
                    isExpanded: true,
                    underline: Container(),
                    items: scoreGames!.map<DropdownMenuItem<int>>((game) {
                      return DropdownMenuItem<int>(
                        value: game['id'],
                        child: Text(game['title'] ?? 'Score Game ${game['id']}'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedScoreGameId = newValue;
                        });
                        getScoreGameDetails(newValue);
                      }
                    },
                  ),
                ),

              SizedBox(
                height: screenHeight * 0.1,
              ),

              // Leaderboard Butonu
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                        AppConstants.scoreGameGreen),
                    foregroundColor:
                    WidgetStateProperty.all<Color>(Colors.black),
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape:
                    WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: () {
                    // Leaderboard sayfasına git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LeaderboardView(
                            scoreGameId: selectedScoreGameId,
                          )),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.leaderboard,
                        color: Colors.white,
                        size: screenWidth * 0.03,
                      ),
                      SizedBox(
                        width: screenWidth * 0.01,
                      ),
                      Text(
                        'Leaderboard', // Lokalizasyon ekleyebilirsiniz
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )),

              SizedBox(height: 10),

              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                        AppConstants.scoreGameGreen),
                    foregroundColor:
                    WidgetStateProperty.all<Color>(Colors.black),
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape:
                    WidgetStateProperty.all<RoundedRectangleBorder>(
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
                      Text(
                        AppLocalizations.of(context)
                            .translate('score_history'),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )),

              SizedBox(
                height: screenHeight * 0.1,
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
                        backgroundColor: WidgetStateProperty.all<Color>(
                            AppConstants.scoreGameGreen),
                        foregroundColor:
                        WidgetStateProperty.all<Color>(Colors.white),
                        padding:
                        WidgetStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(12),
                        ),
                        shape: WidgetStateProperty.all<
                            RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      onPressed: () {
                        if (selectedScoreGameId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No active score game found')),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              contentPadding: EdgeInsets.zero,
                              content: SizedBox(
                                width: screenWidth * 0.9,
                                height: screenHeight * 0.9,
                                child: QRViewExample(
                                  scoreGameId: selectedScoreGameId!,
                                  onQrSuccess: (addedPoints) {
                                    setState(() {
                                      myScores?['total_points'] =
                                          (myScores?['total_points'] ?? 0) + addedPoints;
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
                          Text(
                            AppLocalizations.of(context)
                                .translate('scan_qr_code'),
                            style: const TextStyle(fontSize: 25),
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
  final int scoreGameId;
  final Function(int) onQrSuccess;

  const QRViewExample({
    Key? key,
    required this.scoreGameId,
    required this.onQrSuccess
  }) : super(key: key);

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
        responseText = AppLocalizations.of(context)
            .translate('invalid_qr_code');
      });
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // API dokümanına göre QR kod gönderme endpoint'i belirtilmemiş
    // Muhtemelen POST /api/v1/score-games/{scoreGameId}/scan veya benzeri olmalı
    // Backend'den doğru endpoint'i öğrenin
    final url = Uri.parse('https://api.kongrepad.com/api/v1/score-games/${widget.scoreGameId}/scan');

    // Daha önce okutulmuş QR kodlarını al
    List<String>? scannedCodes = prefs.getStringList('scannedCodes_${widget.scoreGameId}') ?? [];

    if (scannedCodes.contains(code)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text(
              AppLocalizations.of(context).translate('already_scanned'),
            ),
          );
        },
      );

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
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, String>{'code': code}),
      );

      print('QR Scan Response Status: ${response.statusCode}');
      print('QR Scan Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          int addedPoints = responseData['data']?['points'] ??
              responseData['addedPoints'] ??
              responseData['points'] ?? 0;

          // Callback'i çağır
          widget.onQrSuccess(addedPoints);

          // Taratılan kodu listeye ekle ve kaydet
          scannedCodes.add(code);
          prefs.setStringList('scannedCodes_${widget.scoreGameId}', scannedCodes);

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: RichText(
                  text: TextSpan(
                    text: AppLocalizations.of(context)
                        .translate('success_message_part1'),
                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16),
                    children: [
                      TextSpan(
                        text: '${addedPoints.toString()} ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      TextSpan(
                        text: AppLocalizations.of(context).translate(
                            'success_message_part2'),
                      ),
                    ],
                  ),
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
            responseText = responseData['message'] ??
                AppLocalizations.of(context).translate('invalid_qr_code');
          });
        }
      } else {
        setState(() {
          responseText = AppLocalizations.of(context)
              .translate('invalid_qr_code');
        });
      }
    } catch (e) {
      setState(() {
        responseText =
        '${AppLocalizations.of(context).translate('error_occurred')}: $e';
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

// Leaderboard Widget (basit versiyon)
class LeaderboardView extends StatelessWidget {
  final int? scoreGameId;

  const LeaderboardView({Key? key, this.scoreGameId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppConstants.backgroundBlue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Leaderboard yüklenemedi'));
          }

          final leaderboardData = snapshot.data!;
          final leaderboard = leaderboardData['data'] as List? ?? [];

          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final participant = leaderboard[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppConstants.scoreGameGreen,
                  child: Text('${index + 1}'),
                ),
                title: Text(participant['name'] ?? 'Participant ${index + 1}'),
                trailing: Text(
                  '${participant['total_points'] ?? 0} pts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _getLeaderboard() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      String url;
      if (scoreGameId != null) {
        url = 'https://api.kongrepad.com/api/v1/score-games/$scoreGameId/leaderboard';
      } else {
        url = 'https://api.kongrepad.com/api/v1/score-games/overall-leaderboard';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Leaderboard Error: $e');
    }
    return null;
  }
}