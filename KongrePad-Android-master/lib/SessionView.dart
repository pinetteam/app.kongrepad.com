import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:kongrepad/AskQuestionView.dart';
import 'package:kongrepad/Models/Document.dart';
import 'package:kongrepad/Models/Participant.dart';
import 'package:kongrepad/Models/Session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

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
          : Column(
        children: [
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
                      onTap:() {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: screenHeight*0.05,
                        width: screenHeight*0.05,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white, // Circular background color
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/icon/chevron.left.svg',
                            color:AppConstants.backgroundBlue,
                            height: screenHeight*0.03,
                          ),
                        ),
                      ),
                    ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sunum İzle",
                        style: TextStyle(fontSize: 25, color: Colors.white),
                      ),
                    ]
                  ),
                ],
              ),
            ),
          ),
          session != null && document != null && document?.allowedToReview == 1 ?
          Column(
            children: [
              Container(
                height: screenHeight*0.8,
                child: SfPdfViewer.network(
                  'https://app.kongrepad.com/storage/documents/${document?.fileName}.${document?.fileExtension}'),
              ),
              SizedBox(height: screenHeight*0.01),
              SizedBox(
                width: screenWidth * 0.45,
                height: 60,
                child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.redAccent),
                      foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                        const EdgeInsets.all(12),
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (participant?.type! != "attendee") {
                        // todo alert soru sorma izniniz yok
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AskQuestionView(
                                  hallId: widget.hallId)),
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
                          height: 75,
                        ),
                        SizedBox(width: screenWidth*0.01),
                        const Text(
                          'Soru Sor',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    )),
              ),
            ],
          ) :
              Container(
                height: screenHeight*0.8,
                alignment: Alignment.center,
                child: session == null ? const Text(
                  "Aktif oturum bulunamadı",
                  style: TextStyle(fontSize: 25, color: Colors.white),
                ) :
                document == null ? const Text(
                  "Aktif döküman bulunamadı",
                  style: TextStyle(fontSize: 25, color: Colors.white),
                ) : Padding(
                  padding: EdgeInsets.all(25),
                  child: const Text(
                    "Sunum önizlemeğe kapalıdır!",
                    style: TextStyle(fontSize: 25, color: Colors.white),
                  ),
                ),
              ),

        ]
      )
    );
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
