import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/ScoreGamePoint.dart';
import '../utils/app_constants.dart';

class ScoreGamePointsView extends StatefulWidget {
  const ScoreGamePointsView({super.key});

  @override
  State<ScoreGamePointsView> createState() => _ScoreGamePointsViewState();
}

class _ScoreGamePointsViewState extends State<ScoreGamePointsView> {
  List<ScoreGamePoint>? points;
  bool _loading = true;

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("Token bulunamadı, kullanıcı giriş yapmamış.");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    print("Token bulundu: $token");

    try {
      final url =
          Uri.parse('http://app.kongrepad.com/api/v1/score-game/0/point');
      print("URL: $url");

      final response = await http.get(
        url,
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      print("API isteği tamamlandı. Status Code: ${response.statusCode}");
      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          try {
            final jsonData = jsonDecode(response.body);
            final pointsJson = ScoreGamePointsJSON.fromJson(jsonData);

            setState(() {
              points = pointsJson.data;
              _loading = false;
            });

            print("Veri başarıyla alındı: $points");
          } catch (e) {
            print('JSON Çözümleme Hatası: $e');
          }
        } else {
          print("Beklenmeyen Yanıt Formatı: ${response.body}");
        }
      } else {
        print("Sunucu Hatası (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print('Ağ veya Çözümleme Hatası: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
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
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  height: screenHeight * 0.1,
                  decoration:
                      const BoxDecoration(color: AppConstants.virtualStandBlue),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: screenHeight * 0.05,
                          width: screenHeight * 0.05,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.backgroundBlue,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/icon/chevron.left.svg',
                              color: Colors.white,
                              height: screenHeight * 0.03,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('score_history'),
                          style: const TextStyle(
                              fontSize: 25, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: points?.length ?? 0,
                    itemBuilder: (context, index) {
                      final point = points![index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: screenWidth * 0.2,
                                decoration: BoxDecoration(
                                  color: AppConstants.programBackgroundYellow,
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  '${point.point}', // Puan gösteriliyor
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: AppConstants.backgroundBlue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 5),
                              // İkinci Container: Session adı ve tarih bilgisi
                              Container(
                                width: screenWidth * 0.6,
                                alignment: AlignmentDirectional.centerStart,
                                decoration: BoxDecoration(
                                  color: AppConstants.hallsButtonBlue,
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      point.title.toString(), // Session adı
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      point.createdAt
                                          .toString(), // Tarih bilgisi
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
