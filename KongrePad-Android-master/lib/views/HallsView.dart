import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kongrepad/views/AskQuestionView.dart';
import 'package:kongrepad/Models/Hall.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/views/ProgramDaysView.dart';
import 'package:kongrepad/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'SessionView.dart';

class HallsView extends StatefulWidget {
  const HallsView({super.key, required this.type});

  final String type;

  @override
  State<HallsView> createState() => _HallsViewState(type);
}

class _HallsViewState extends State<HallsView> {
  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/hall');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final hallsJson = HallsJSON.fromJson(jsonData);
        setState(() {
          halls = hallsJson.data;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  final String type;
  bool _loading = true;
  List<Hall>? halls;

  _HallsViewState(this.type);

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
                              width: 1, // Border width
                            ),
                          ),
                        ),
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
                                  height: screenHeight * 0.04,
                                  width: screenHeight * 0.04,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors
                                        .white, // Circular background color
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
                                          .translate('select_hall'),                                      style: TextStyle(
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
                          height: screenHeight * 0.7,
                          width: screenWidth,
                          child: Column(
                            children: halls?.map((hall) {
                                  return Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: SizedBox(
                                      width: screenWidth * 0.7,
                                      child: ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  AppConstants.hallsButtonBlue),
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  AppConstants.backgroundBlue),
                                          padding: MaterialStateProperty.all<
                                              EdgeInsetsGeometry>(
                                            const EdgeInsets.all(12),
                                          ),
                                          shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          if (type == "program") {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: AppConstants
                                                      .backgroundBlue,
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  content: SizedBox(
                                                    width: screenWidth * 0.9,
                                                    height: screenHeight * 0.8,
                                                    child: ProgramDaysView(
                                                        hallId: hall.id!),
                                                  ),
                                                );
                                              },
                                            );
                                          } else if (type == "question") {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      AskQuestionView(
                                                          hallId: hall.id!)),
                                            );
                                          } else if (type == "session") {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      SessionView(
                                                          hallId: hall.id!)),
                                            );
                                          }
                                        },
                                        child: Text(
                                          hall.title.toString(),
                                          style: TextStyle(fontSize: 20),
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
                )),
    );
  }
}
