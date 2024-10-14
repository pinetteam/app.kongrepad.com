import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kongrepad/AlertService.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/Models/Hall.dart';
import 'package:kongrepad/Models/Program.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgramMailView extends StatefulWidget {
  const ProgramMailView(
      {super.key, required this.programDay, required this.hallId});

  final ProgramDay programDay;
  final int hallId;

  @override
  State<ProgramMailView> createState() =>
      _ProgramMailViewState(programDay, hallId);
}

class _ProgramMailViewState extends State<ProgramMailView> {
  ProgramDay? programDay;
  Hall? hall;
  final int hallId;
  Set<int> documents = {};
  bool _sending = false;
  bool _loading = true;

  _ProgramMailViewState(this.programDay, this.hallId);

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
                    const Text(
                      "Mail Gönder",
                      style: TextStyle(fontSize: 25, color: Colors.white),
                    ),
                    const SizedBox(width: 55), // Ortalamayı sağlamak için.
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
                            fontSize: 23, color: Colors.black),
                      ),
                      Text(
                        programDay!.day.toString(),
                        style: const TextStyle(
                            fontSize: 20, color: Colors.grey),
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
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Text(
                                        program.startAt.toString(),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: AppConstants
                                                .backgroundBlue),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        program.finishAt.toString(),
                                        style: const TextStyle(
                                            fontSize: 18,
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
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        program.title.toString(),
                                        style: const TextStyle(
                                            fontSize: 18,
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
                                              fontSize: 16,
                                              color: CupertinoColors.black),
                                        ),
                                      if (program.description != null)
                                        Text(
                                          program.description.toString(),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: CupertinoColors
                                                  .systemGrey),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  );
                },
              ),
// Mail Gönder Butonu
              Container(
                width: screenWidth,
                height: screenHeight * 0.1,
                decoration: BoxDecoration(color: AppConstants.buttonYellow),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.programBackgroundYellow,
                      ),
                      onPressed: _sending
                          ? null
                          : () {
                        _sendMail();
                      },
                      child: _sending
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                          SizedBox(
                            width: 10,
                          ),
                          const Text(
                            'Gönder',
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMail() async {
    setState(() {
      _sending = true;
    });
    final url = Uri.parse('https://app.kongrepad.com/api/v1/mail');
    final body = jsonEncode({
      'documents': "[${documents.map((int e) => e.toString()).join(",")}]",
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    http
        .post(
      url,
      headers: {
        'Authorization': 'Bearer ${prefs.getString('token')}',
        'Content-Type': 'application/json',
      },
      body: body,
    )
        .then((response) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        AlertService().showAlertDialog(
          context,
          title: 'Başarılı',
          content: "Paylaşıma izin verilen sunumlardan talep ettikleriniz kongreden sonra tarafınıza mail olarak gönderilecektir.",
        );
        Navigator.of(context).pop();
      } else {
        AlertService().showAlertDialog(
          context,
          title: 'Hata',
          content: 'Bir hata meydana geldi.',
        );
      }
      setState(() {
        _sending = false;
      });
    }).catchError((error) {
      print(error);
      setState(() {
        _sending = false;
      });
    });
  }
}
