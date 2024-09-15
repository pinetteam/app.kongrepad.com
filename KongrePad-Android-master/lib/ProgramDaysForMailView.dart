import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/AlertService.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:kongrepad/Models/Program.dart';
import 'package:kongrepad/ProgramMailView.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                      const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Gün Seçiniz",
                              style: TextStyle(
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
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                MaterialStateProperty
                                    .all<Color>(AppConstants
                                    .hallsButtonBlue),
                                foregroundColor:
                                MaterialStateProperty
                                    .all<Color>(AppConstants
                                    .backgroundBlue),
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
                                      day.day.toString(),
                                      style:
                                      TextStyle(fontSize: 20),
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
                BoxDecoration(color: AppConstants.buttonYellow),
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
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      )
                          : Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icon/envelope.open.fill.svg',
                            color: Colors.black,
                            height: screenHeight * 0.02,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          const Text(
                            'İzin Verilen Tüm Sunumları Gönder',
                            style: TextStyle(
                                fontSize: 17,
                                color: Colors.black),
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
        title: 'Başarılı',
        content:
        "İstediğiniz dökümanlar kongreden sonra size mail olarak gönderilecek",
      );
      setState(() {
        _sending = false;
      });
    }).catchError((error) {
      AlertService().showAlertDialog(
        context,
        title: 'Hata',
        content: "Bir hata meydana geldi!",
      );
      setState(() {
        _sending = false;
      });
    });
  }
}
