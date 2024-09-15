import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/Models/Hall.dart';
import 'package:kongrepad/Models/Program.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgramView extends StatefulWidget {
  const ProgramView({super.key, required this.programDay, required this.hallId});

  final ProgramDay programDay;
  final int hallId;

  @override
  State<ProgramView> createState() => _ProgramViewState(programDay, hallId);
}

class _ProgramViewState extends State<ProgramView> {
  ProgramDay? programDay;
  Hall? hall;
  final int hallId;
  bool _loading = true;

  _ProgramViewState(this.programDay, this.hallId);

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ;

    try {
      final url = Uri.parse('https://app.kongrepad.com/api/v1/hall/$hallId');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final hallJson = HallJSON.fromJson(jsonData);
        setState(() {
          hall = hallJson.data;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

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
          color: AppConstants.programBackgroundYellow,
          height: screenHeight,
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  height: screenHeight * 0.1,
                  decoration: const BoxDecoration(color: AppConstants.buttonYellow),
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
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
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
                                "Bilimsel Program",
                                style: TextStyle(fontSize: 25, color: Colors.white),
                              )
                            ]),
                      ],
                    ),
                  ),
                ),


                SizedBox(height: screenHeight*0.01,),
                SingleChildScrollView(
                  child: SizedBox(
                    width: screenWidth * 0.96,
                    height: screenHeight*0.10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppConstants.programBackgroundYellow,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Column(
                                children: [
                                  Text(
                                    hall?.title.toString() ?? "",
                                    style: TextStyle(
                                        fontSize: 23,
                                        color: Colors.black),
                                  ),
                                  Text(
                                    programDay!.day.toString(),
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),

                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.topCenter,
                  width: screenWidth,
                  height: screenHeight * 0.763,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Container(
                      width: screenWidth,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: programDay!.programs!.map((program) {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: screenWidth * 0.2,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppConstants.programBackgroundYellow,
                                            border: Border.all(color: Colors.black),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          padding: EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              Text(
                                                program.startAt.toString(),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color: AppConstants.backgroundBlue),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: double.infinity,
                                                  width: screenWidth*0.006,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                program.finishAt.toString(),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color: AppConstants.backgroundBlue),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10,),
                                      Expanded(
                                        child: SizedBox(
                                          width: screenWidth * 0.6,
                                          child: Container(
                                            alignment: AlignmentDirectional.centerStart,
                                            decoration: BoxDecoration(
                                              color: AppConstants.hallsButtonBlue,
                                              border: Border.all(color: Colors.black),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            padding: EdgeInsets.all(12),
                                            child: Container(
                                              child:Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    program.title.toString(),
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.black),
                                                  ),
                                                  program.chairs!.isNotEmpty ? Text(
                                                    (program.chairs?.length == 1 ? "Moderatör: " : "Moderatörler: ") + program.chairs!.map((chair) => chair.fullName).join(', ').toString(),
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        color: CupertinoColors.systemGrey),
                                                  ) : Container(),
                                                  program.description != null ? Text(
                                                    program.description.toString(),
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        color: CupertinoColors.systemGrey),
                                                  ) : Container(),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              program.type == "session" && program.sessions?.length !=0 ?
                              Column(
                                  children: program.sessions!.map((session)
                                  {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: screenWidth * 0.2,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppConstants.programBackgroundYellow,
                                                  border: Border.all(color: Colors.black),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                padding: EdgeInsets.all(12),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      session.startAt.toString(),
                                                      style: const TextStyle(
                                                          fontSize: 20,
                                                          color: AppConstants.backgroundBlue),
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        height: double.infinity,
                                                        width: screenWidth*0.006,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      session.finishAt.toString(),
                                                      style: const TextStyle(
                                                          fontSize: 20,
                                                          color: AppConstants.backgroundBlue),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10,),
                                            SizedBox(
                                              width: screenWidth * 0.65,
                                              child: Container(
                                                alignment: AlignmentDirectional.centerStart,
                                                decoration: BoxDecoration(
                                                  color: AppConstants.hallsButtonBlue,
                                                  border: Border.all(color: Colors.black),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                padding: EdgeInsets.all(12),
                                                child: Container(
                                                  child:Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        session.title.toString(),
                                                        textAlign: TextAlign.start,
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            color: Colors.black),
                                                      ),
                                                      session.speakerName != null ? Text(
                                                        "Konuşmacı: " + session.speakerName.toString(),
                                                        textAlign: TextAlign.start,
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            color: CupertinoColors.systemGrey),
                                                      ) : Container(),
                                                      session.description != null ? Text(
                                                        session.description.toString(),
                                                        textAlign: TextAlign.start,
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            color: CupertinoColors.systemGrey),
                                                      ) : Container(),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList()) : Container(),
                              program.type == "debate" && program.debates?.length !=0 ?
                              Column(
                                  children: program.debates!.map((debate)
                                  {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: screenWidth * 0.2,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppConstants.programBackgroundYellow,
                                                  border: Border.all(color: Colors.black),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                padding: EdgeInsets.all(12),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      debate.votingStartedAt.toString(),
                                                      style: const TextStyle(
                                                          fontSize: 20,
                                                          color: AppConstants.backgroundBlue),
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        height: double.infinity,
                                                        width: screenWidth*0.006,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      debate.votingFinishedAt.toString(),
                                                      style: const TextStyle(
                                                          fontSize: 20,
                                                          color: AppConstants.backgroundBlue),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10,),
                                            Expanded(
                                              child: SizedBox(
                                                width: screenWidth * 0.65,
                                                child: Container(
                                                  alignment: AlignmentDirectional.centerStart,
                                                  decoration: BoxDecoration(
                                                    color: AppConstants.hallsButtonBlue,
                                                    border: Border.all(color: Colors.black),
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  padding: EdgeInsets.all(12),
                                                  child: Container(
                                                    child:Column(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          debate.title.toString(),
                                                          textAlign: TextAlign.start,
                                                          style: TextStyle(
                                                              fontSize: 20,
                                                              color: Colors.black),
                                                        ),
                                                        debate.teams!.isNotEmpty
                                                            ? Column(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                          children: debate
                                                              .teams!
                                                              .map((team) =>
                                                              Column(
                                                                children: [
                                                                  Text(
                                                                    team.title.toString(),
                                                                    textAlign:
                                                                    TextAlign.start,
                                                                    style:
                                                                    TextStyle(
                                                                      fontSize: 20,
                                                                      color: CupertinoColors.systemGrey,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    team.description.toString(),
                                                                    textAlign:
                                                                    TextAlign.start,
                                                                    style:
                                                                    TextStyle(
                                                                      fontSize: 20,
                                                                      color: CupertinoColors.systemGrey,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ))
                                                              .toList(),
                                                        )
                                                            : Container(),
                                                        debate.description != null ? Text(
                                                          debate.description.toString(),
                                                          textAlign: TextAlign.start,
                                                          style: TextStyle(
                                                              fontSize: 20,
                                                              color: CupertinoColors.systemGrey),
                                                        ) : Container(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList()) : Container(),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
