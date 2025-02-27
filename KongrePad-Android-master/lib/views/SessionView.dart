import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kongrepad/views/AskQuestionView.dart';
import 'package:kongrepad/Models/Document.dart';
import 'package:kongrepad/Models/Participant.dart';
import 'package:kongrepad/Models/Session.dart';
import 'package:kongrepad/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';

class SessionView extends StatefulWidget {
  const SessionView({super.key, required this.hallId});

  final int hallId;

  @override
  State<SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<SessionView> {
  Session? session;
  Document? document;
  Participant? participant;
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
    return Scaffold(
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Column(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  height: 80,
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
                            height: screenHeight * 0.05,
                            width: screenHeight * 0.05,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white, // Circular background color
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
                                    .translate('watch_presentation'),
                                style: TextStyle(
                                    fontSize: 25, color: Colors.white),
                              ),
                            ]),
                      ],
                    ),
                  ),
                ),
                session != null &&
                        document != null &&
                        document?.allowedToReview == 1
                    ? Column(
                        children: [
                          Container(
                            height: screenHeight * 0.8,
                            child: SfPdfViewer.network(
                                'https://app.kongrepad.com/storage/documents/${document?.fileName}.${document?.fileExtension}'),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          SizedBox(
                            width: screenWidth * 0.45,
                            height: 60,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(Colors.redAccent),
                                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                                  EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.015, // Ekran yüksekliğine göre padding
                                    horizontal: screenWidth * 0.05, // Ekran genişliğine göre padding
                                  ),
                                ),
                                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                if (participant?.type! != "attendee") {
                                  // todo: alert soru sorma izniniz yok
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AskQuestionView(hallId: widget.hallId),
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icon/questionmark.svg',
                                    color: Colors.white,
                                    height: screenHeight * 0.05,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        AppLocalizations.of(context).translate('ask_question'),
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          ),
                        ],
                      )
                    : Container(
                        height: screenHeight * 0.8,
                        alignment: Alignment.center,
                        child: session == null
                            ? Text(
                                AppLocalizations.of(context)
                                    .translate('no_active_session'),
                                style: TextStyle(
                                    fontSize: 25, color: Colors.white),
                              )
                            : document == null
                                ? Text(
                                    AppLocalizations.of(context)
                                        .translate('no_active_document'),
                                    style: TextStyle(
                                        fontSize: 25, color: Colors.white),
                                  )
                                : Padding(
                                    padding: EdgeInsets.all(25),
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .translate('preview_closed'),
                                      style: TextStyle(
                                          fontSize: 25, color: Colors.white),
                                    ),
                                  ),
                      ),
              ]));
  }

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse(
          'https://app.kongrepad.com/api/v1/hall/${widget.hallId}/active-session');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final sessionJson = SessionJSON.fromJson(jsonData);
        setState(() {
          session = sessionJson.data!;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
    }

    try {
      final url = Uri.parse(
          'https://app.kongrepad.com/api/v1/hall/${widget.hallId}/active-document');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final documentJson = DocumentJSON.fromJson(jsonData);
        setState(() {
          document = documentJson.data!;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/participant');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final participantJson = ParticipantJSON.fromJson(jsonData);
        setState(() {
          participant = participantJson.data;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
