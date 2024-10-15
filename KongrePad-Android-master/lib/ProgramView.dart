import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    final token = prefs.getString('token');

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
      backgroundColor: AppConstants.programBackgroundYellow,
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Üst kısımdaki başlık
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppConstants.buttonYellow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
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
                    Padding(
                      padding: EdgeInsets.only(right: 80),
                      child: const Text(
                        "Bilimsel Program",
                        style: TextStyle(
                            fontSize: 25, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.01),

              // Ana salon ve program günü kısmı
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.programBackgroundYellow,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        hall?.title.toString() ?? "",
                        style: const TextStyle(
                            fontSize: 25, color: Colors.black),
                      ),
                      Text(
                        programDay!.day.toString(),
                        style: const TextStyle(
                            fontSize: 20, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),

              // Program listesi
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: programDay?.programs?.length ?? 0,
                itemBuilder: (context, index) {
                  final program = programDay!.programs![index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: screenWidth * 0.3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppConstants
                                        .programBackgroundYellow,
                                    border: Border.all(
                                        color: Colors.black),
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Text(
                                        program.startAt.toString(),
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: AppConstants
                                                .backgroundBlue),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        program.finishAt.toString(),
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: AppConstants
                                                .backgroundBlue),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppConstants.hallsButtonBlue,
                                    border: Border.all(
                                        color: Colors.black),
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        program.title.toString(),
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black),
                                      ),
                                      if (program.chairs!.isNotEmpty)
                                        Text(
                                          (program.chairs!.length == 1
                                              ? "Moderatör: "
                                              : "Moderatörler: ") +
                                              program.chairs!
                                                  .map((chair) =>
                                              chair.fullName)
                                                  .join(', '),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              color: CupertinoColors
                                                  .black),
                                        ),
                                      if (program.description != null)
                                        Text(
                                          program.description.toString(),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              color: CupertinoColors
                                                  .black),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sessions gösterimi
                        if (program.type == "session" &&
                            program.sessions?.isNotEmpty == true)
                          Column(
                            children: program.sessions!.map((session) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: screenWidth * 0.3,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppConstants
                                                .programBackgroundYellow,
                                            border: Border.all(
                                                color: Colors.black),
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                          padding:
                                          const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              Text(
                                                session.startAt
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color: AppConstants
                                                        .backgroundBlue),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                session.finishAt
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color: AppConstants
                                                        .backgroundBlue),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppConstants
                                                .hallsButtonBlue,
                                            border: Border.all(
                                                color: Colors.black),
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                          padding:
                                          const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                session.title.toString(),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color:
                                                    Colors.black),
                                              ),
                                              if (session.speakerName !=
                                                  null)
                                                Text(
                                                  "Konuşmacı: ${session.speakerName}",
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      color: CupertinoColors
                                                          .black),
                                                ),
                                              if (session.description !=
                                                  null)
                                                Text(
                                                  session.description
                                                      .toString(),
                                                  style: const TextStyle(

                                                      fontSize: 18,
                                                      color: CupertinoColors
                                                          .black),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        // Debates gösterimi
                        if (program.type == "debate" &&
                            program.debates?.isNotEmpty == true)
                          Column(
                            children: program.debates!.map((debate) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: screenWidth * 0.3,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppConstants
                                                .programBackgroundYellow,
                                            border: Border.all(
                                                color: Colors.black),
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                          padding:
                                          const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              Text(
                                                debate.votingStartedAt
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color: AppConstants
                                                        .backgroundBlue),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                debate.votingFinishedAt
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color: AppConstants
                                                        .backgroundBlue),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppConstants
                                                .hallsButtonBlue,
                                            border: Border.all(
                                                color: Colors.black),
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                          padding:
                                          const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                debate.title.toString(),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color:
                                                    Colors.black),
                                              ),
                                              if (debate.teams != null)
                                                Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: debate.teams!
                                                      .map((team) {
                                                    return Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        Text(
                                                          team.title
                                                              .toString(),
                                                          style: const TextStyle(
                                                              fontSize:
                                                              18,
                                                              color: CupertinoColors
                                                                  .black),
                                                        ),
                                                        if (team
                                                            .description !=
                                                            null)
                                                          Text(
                                                            team.description
                                                                .toString(),
                                                            style: const TextStyle(
                                                                fontSize:
                                                                18,
                                                                color: CupertinoColors
                                                                    .black),
                                                          ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              if (debate.description !=
                                                  null)
                                                Text(
                                                  debate.description
                                                      .toString(),
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      color: CupertinoColors
                                                          .black),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
