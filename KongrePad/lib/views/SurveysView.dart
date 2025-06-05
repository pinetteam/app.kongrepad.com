import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/Survey.dart';
import '../utils/app_constants.dart';
import 'MainPageView.dart';
import 'SurveyView.dart';

class SurveysView extends StatefulWidget {
  const SurveysView({super.key});

  @override
  State<SurveysView> createState() => _SurveysViewState();
}

class _SurveysViewState extends State<SurveysView> {
  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('SurveysView - getData başladı');
    print('SurveysView - Token: ${token?.substring(0, 10)}...');

    try {
      // ✅ Doğru URL - Swagger'a göre güncellendi
      final url = Uri.parse('https://api.kongrepad.com/api/v1/surveys');
      print('SurveysView - Request URL: $url');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('SurveysView - Response Status: ${response.statusCode}');
      print('SurveysView - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('SurveysView - JSON Data Keys: ${jsonData.keys}');

        // API response yapısını kontrol et
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final surveysJson = SurveysJSON.fromJson(jsonData);
          setState(() {
            surveys = surveysJson.data;
            _loading = false;
          });
          print('SurveysView - ${surveys?.length} survey bulundu');
        } else {
          print('SurveysView - API success=false veya data=null');
          print('SurveysView - Message: ${jsonData['message']}');
          setState(() {
            surveys = [];
            _loading = false;
          });
        }
      } else if (response.statusCode == 401) {
        print('SurveysView - Unauthorized (401)');
        setState(() {
          _loading = false;
        });
      } else {
        print('SurveysView - HTTP Error: ${response.statusCode}');
        print('SurveysView - Error Body: ${response.body}');
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('SurveysView - Exception Error: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  List<Survey>? surveys;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    return SafeArea(
      child: Scaffold(
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Container(
          height: screenHeight,
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                height: screenHeight * 0.1,
                decoration: const BoxDecoration(
                  color: AppConstants.backgroundBlue,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white, // Border color
                      width: 2, // Border width
                    ),
                  ),
                ),
                child: SizedBox(
                  width: screenWidth,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MainPageView(
                                  title: '',
                                )),
                          );
                        },
                        child: Container(
                          height: screenHeight * 0.05,
                          width: screenHeight * 0.05,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                            Colors.white, // Circular background color
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
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .translate('surveys'),
                              style: const TextStyle(
                                  fontSize: 25, color: Colors.white),
                            )
                          ]),
                    ],
                  ),
                ),
              ),
              // Surveys listesi
              Expanded(
                child: surveys == null || surveys!.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.poll_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz anket bulunmuyor',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                          });
                          getData();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yenile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.backgroundBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: surveys!.map((survey) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.1,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                              WidgetStateProperty.all<Color>(
                                  survey.isCompleted == true
                                      ? Colors.redAccent
                                      : AppConstants
                                      .buttonDarkBlue),
                              foregroundColor:
                              WidgetStateProperty.all<Color>(
                                  AppConstants.backgroundBlue),
                              padding: WidgetStateProperty.all<
                                  EdgeInsetsGeometry>(
                                const EdgeInsets.all(12),
                              ),
                              shape: WidgetStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            onPressed: () {
                              print('Survey tıklandı: ${survey.id} - ${survey.title}');
                              // Navigate to SurveyView with isEditable flag
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SurveyView(
                                    survey: survey,
                                    isEditable: !(survey
                                        .isCompleted ??
                                        false), // Provide a default value of false if isCompleted is null
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SvgPicture.asset(
                                    'assets/icon/checklist.checked.svg',
                                    color: Colors.white,
                                    height: screenHeight * 0.03,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    survey.title.toString(),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (survey.isCompleted == true)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}