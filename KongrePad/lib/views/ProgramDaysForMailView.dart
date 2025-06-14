import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/Program.dart';
import '../services/alert_service.dart';
import '../utils/app_constants.dart';
import 'ProgramMailView.dart';

String translateDate(String englishDate, BuildContext context) {
  String translatedDate = englishDate;

  dayTranslations.forEach((english, turkish) {
    final translation =
        AppLocalizations.of(context).translate(english.toLowerCase());
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, translation);
    }
  });

  monthTranslations.forEach((english, turkish) {
    final translation =
        AppLocalizations.of(context).translate(english.toLowerCase());
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, translation);
    }
  });

  return translatedDate;
}

class ProgramDaysForMailView extends StatefulWidget {
  const ProgramDaysForMailView({super.key, required this.hallId});

  final int hallId;

  @override
  State<ProgramDaysForMailView> createState() =>
      _ProgramDaysForMailViewState(hallId);
}

class _ProgramDaysForMailViewState extends State<ProgramDaysForMailView> {
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
  List<ProgramDay>? programDays;
  bool _sending = false;
  bool _loading = true;

  _ProgramDaysForMailViewState(this.hallId);

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
                alignment: Alignment.center,
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
                                Navigator.pop(context);
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
                      child: Container(
                        alignment: Alignment.topCenter,
                        height: screenHeight * 0.775,
                        width: screenWidth,
                        child: Column(
                          children: programDays?.map((day) {
                                String translatedDay =
                                    translateDateToTurkish(day.day.toString());

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
                                                    ProgramMailView(
                                                      programDay: day,
                                                      hallId: hallId,
                                                    )),
                                          );
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icon/chevron.right.2.svg',
                                              color:
                                                  AppConstants.backgroundBlue,
                                              height: screenHeight * 0.03,
                                            ),
                                            SizedBox(
                                              width: screenWidth * 0.05,
                                            ),
                                            Flexible(
                                              child: Text(
                                                translatedDay,
                                                style: const TextStyle(
                                                    fontSize: 20),
                                              ),
                                            ),
                                          ],
                                        )),
                                  ),
                                );
                              }).toList() ??
                              [],
                        ),
                      ),
                    ),
                    Container(
                      width: screenWidth,
                      height: screenHeight * 0.1,
                      decoration:
                          const BoxDecoration(color: AppConstants.buttonYellow),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppConstants.programBackgroundYellow),
                            onPressed: _sending
                                ? null
                                : () {
                                    _sendAllMail();
                                  },
                            child: _sending
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icon/envelope.open.fill.svg',
                                        color: Colors.black,
                                        height: screenHeight * 0.02,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        AppLocalizations.of(context)
                                            .translate("send_all_documents"),
                                        style: const TextStyle(
                                            fontSize: 17, color: Colors.black),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ));
  }

  Future<void> _sendAllMail() async {
    setState(() {
      _sending = true;
    });
    final url = Uri.parse('https://app.kongrepad.com/api/v1/mail_send_all');

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${prefs.getString('token')}',
        'Content-Type': 'application/json',
      },
    ).then((response) {
      final jsonResponse = jsonDecode(response.body);
      AlertService().showAlertDialog(
        context,
        title: AppLocalizations.of(context).translate("success"),
        content: AppLocalizations.of(context).translate("sending_success"),
      );
      setState(() {
        _sending = false;
      });
    }).catchError((error) {
      AlertService().showAlertDialog(
        context,
        title: AppLocalizations.of(context).translate("error"),
        content: AppLocalizations.of(context).translate("sending_error"),
      );
      setState(() {
        _sending = false;
      });
    });
  }
}
