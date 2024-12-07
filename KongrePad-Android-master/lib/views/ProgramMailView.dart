import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/Models/Hall.dart';
import 'package:kongrepad/Models/Program.dart';
import 'package:kongrepad/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

Map<String, String> dayTranslations = {
  'Monday': 'Pazartesi',
  'Tuesday': 'Salı',
  'Wednesday': 'Çarşamba',
  'Thursday': 'Perşembe',
  'Friday': 'Cuma',
  'Saturday': 'Cumartesi',
  'Sunday': 'Pazar',
};

Map<String, String> monthTranslations = {
  'January': 'Ocak',
  'February': 'Şubat',
  'March': 'Mart',
  'April': 'Nisan',
  'May': 'Mayıs',
  'June': 'Haziran',
  'July': 'Temmuz',
  'August': 'Ağustos',
  'September': 'Eylül',
  'October': 'Ekim',
  'November': 'Kasım',
  'December': 'Aralık',
};

String translateDateToTurkish(String englishDate) {
  String translatedDate = englishDate;

  dayTranslations.forEach((english, turkish) {
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, turkish);
    }
  });

  monthTranslations.forEach((english, turkish) {
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, turkish);
    }
  });

  return translatedDate;
}

double calculateTimeDifference(String start, String end) {
  DateFormat format = DateFormat("HH:mm");
  DateTime startTime = format.parse(start);
  DateTime endTime = format.parse(end);
  return endTime.difference(startTime).inMinutes / 60;
}

class ProgramMailView extends StatefulWidget {
  const ProgramMailView({super.key, required this.programDay, required this.hallId});

  final ProgramDay programDay;
  final int hallId;

  @override
  State<ProgramMailView> createState() => _ProgramMailViewState(programDay, hallId);
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

    // SharedPreferences'ten daha önce seçilmiş belgeleri yükle
    List<String>? savedDocuments = prefs.getStringList('selectedDocuments');
    if (savedDocuments != null) {
      documents = savedDocuments.map((e) => int.parse(e)).toSet();
    }

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
      print('Error fetching data: $e');
    }
  }

  Future<void> _saveSelectionsToPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('selectedDocuments', documents.map((e) => e.toString()).toList());
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
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              children: [
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
                       Text(
                        AppLocalizations.of(context).translate("send_mail"),
                        style: TextStyle(fontSize: 25, color: Colors.white),
                      ),
                      const SizedBox(width: 55),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

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
                          style: const TextStyle(fontSize: 23, color: Colors.black),
                        ),
                        Text(
                          translateDateToTurkish(programDay!.day.toString()),
                          style: const TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: programDay?.programs?.length ?? 0,
                  itemBuilder: (context, index) {
                    final program = programDay!.programs![index];
                    double heightFactor = calculateTimeDifference(program.startAt!, program.finishAt!);

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: screenWidth * 0.25,
                                  decoration: BoxDecoration(
                                    color: AppConstants.programBackgroundYellow,
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        program.startAt ?? "",
                                        style: const TextStyle(fontSize: 18, color: AppConstants.backgroundBlue),
                                      ),
                                      Expanded(
                                        child: Container(
                                          width: 2.0,
                                          color: Colors.black,
                                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                                        ),
                                      ),
                                      Text(
                                        program.finishAt ?? "",
                                        style: const TextStyle(fontSize: 18, color: AppConstants.backgroundBlue),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                Flexible(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppConstants.hallsButtonBlue,
                                      border: Border.all(color: Colors.black),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          program.title.toString(),
                                          style: const TextStyle(fontSize: 18, color: Colors.black),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        if (program.chairs!.isNotEmpty)
                                          Text(
                                            (program.chairs!.length == 1
                                                ?  AppLocalizations.of(context)
                                                .translate("moderator")
                                                : AppLocalizations.of(context)
                                                .translate("moderators")) +
                                                program.chairs!.map((chair) => chair.fullName).join(', '),
                                            style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (program.description != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              program.description.toString(),
                                              style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                        if (program.sessions!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Column(
                                              children: program.sessions!.map((session) {
                                                bool isDisabled = session.isDocumentRequested ?? false;
                                                bool canShare = session.documentSharingViaEmail ?? false;

                                                return Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.black),
                                                    borderRadius: BorderRadius.circular(8),
                                                    color: isDisabled
                                                        ? Colors.grey.shade300
                                                        : Colors.white,
                                                  ),
                                                  child: CheckboxListTile(
                                                    title: Text(
                                                      session.title!,
                                                      style: TextStyle(
                                                        fontSize: screenWidth * 0.04,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    value: documents.contains(session.documentId),
                                                    onChanged: (isDisabled || !canShare)
                                                        ? null
                                                        : (bool? selected) {
                                                      setState(() {
                                                        if (selected == true) {
                                                          documents.add(session.documentId!);
                                                        } else {
                                                          documents.remove(session.documentId!);
                                                        }
                                                      });
                                                      _saveSelectionsToPreferences();
                                                    },
                                                    activeColor: isDisabled
                                                        ? Colors.grey
                                                        : AppConstants.hallsButtonBlue,
                                                    checkColor: Colors.white,
                                                  ),
                                                );
                                              }).toList(),
                                            ),
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
                        onPressed: _sending ? null : () => _sendMail(),
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
                            const SizedBox(width: 10),
                             Text(
                              AppLocalizations.of(context)
                                  .translate("send"),  style: TextStyle(fontSize: 20, color: Colors.black),
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
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status']) {
        await _showDialog(
          AppLocalizations.of(context).translate("successful"),
          AppLocalizations.of(context).translate("mail_sending_success"),
        );
      } else {
        await _showDialog( AppLocalizations.of(context).translate("error"),
          AppLocalizations.of(context).translate("mail_sending_error"),);
      }
    } catch (e) {
      await _showDialog(  AppLocalizations.of(context).translate("error"),
        AppLocalizations.of(context).translate("mail_sending_error"),);
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  Future<void> _showDialog(String title, String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child:  Text(  AppLocalizations.of(context).translate("ok"),
                ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
