import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/Program.dart';
import '../utils/app_constants.dart';
//import 'ProgramMailView.dart';
import 'ProgramView.dart';

String translateDate(String englishDate, BuildContext context) {
  String translatedDate = englishDate;

  dayTranslations.forEach((english, _) {
    final translation =
        AppLocalizations.of(context).translate(english.toLowerCase());
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, translation);
    }
  });

  // Translate month names
  monthTranslations.forEach((english, _) {
    final translation =
        AppLocalizations.of(context).translate(english.toLowerCase());
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, translation);
    }
  });

  return translatedDate;
}

class ProgramDaysView extends StatefulWidget {
  const ProgramDaysView({super.key, required this.hallId});

  final int hallId;

  @override
  State<ProgramDaysView> createState() => _ProgramDaysViewState(hallId);
}

class _ProgramDaysViewState extends State<ProgramDaysView> {
  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url =
          Uri.parse('https://app.kongrepad.com/api/v1/hall/$hallId/program');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final programDaysJson = ProgramsJson.fromJson(jsonData);
        setState(() {
          programDays = programDaysJson.data;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  final int hallId;
  bool _loading = true;
  List<ProgramDay>? programDays;

  _ProgramDaysViewState(this.hallId);

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

    return Scaffold(
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                    color: AppConstants.programBackgroundYellow),
                height: screenHeight,
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        height: screenHeight * 0.1,
                        decoration: const BoxDecoration(
                          color: AppConstants.buttonYellow,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white, // Border color
                              width: 1, // Border width
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
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  height: screenHeight * 0.04,
                                  width: screenHeight * 0.04,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors
                                        .white, // Circular background color
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SvgPicture.asset(
                                      'assets/icon/chevron.left.svg',
                                      color: AppConstants.buttonYellow,
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
                                          .translate("select_day"),
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
                            children: programDays?.map((day) {
                                  String translatedDay =
                                      translateDateToTurkish(day.day!);

                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: screenWidth * 0.8,
                                      child: ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStateProperty.all<Color>(
                                                  AppConstants.hallsButtonBlue),
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
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ProgramView(
                                                      programDay: day,
                                                      hallId: hallId,
                                                    )),
                                          );
                                        },
                                        child: SizedBox(
                                          width:
                                              screenWidth * 0.7, // Adjust width
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                child: SvgPicture.asset(
                                                  'assets/icon/chevron.right.2.svg',
                                                  color: AppConstants
                                                      .backgroundBlue,
                                                  height: screenHeight * 0.03,
                                                ),
                                              ),
                                              SizedBox(
                                                width: screenWidth * 0.03,
                                              ),
                                              Flexible(
                                                child: Center(
                                                  child: Text(
                                                    translatedDay,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
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
              ));
  }
}
