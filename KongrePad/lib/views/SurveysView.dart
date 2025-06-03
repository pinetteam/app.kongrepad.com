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

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/survey');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final surveysJson = SurveysJSON.fromJson(jsonData);
        setState(() {
          surveys = surveysJson.data;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
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
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        height: screenHeight * 0.65,
                        width: screenWidth,
                        child: Column(
                          children: surveys?.map((survey) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: screenWidth * 0.8,
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
                                          Text(
                                            survey.title.toString(),
                                            style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList() ??
                              [],
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
