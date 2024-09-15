import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/AlertService.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:kongrepad/Models/Session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AskQuestionView extends StatefulWidget {
  final int hallId;

  const AskQuestionView({super.key, required this.hallId});

  @override
  _AskQuestionViewState createState() => _AskQuestionViewState();
}

class _AskQuestionViewState extends State<AskQuestionView> {
  Session? _session;
  String _question = '';
  bool _isHiddenName = false;
  bool _asking = false;
  final FocusNode _focusNode = FocusNode();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor:
            AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : GestureDetector(
          onTap: () {
            _focusNode.unfocus();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;
              return Container(
                color: AppConstants.backgroundBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      height: screenHeight * 0.1,
                      decoration: const BoxDecoration(
                        color: AppConstants.backgroundBlue,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white, // Border color
                            width: 1.0, // Border width
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
                                  color:
                                  Colors.white, // Circular background color
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
                            const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Soru sor",
                                    style: TextStyle(
                                        fontSize: 25, color: Colors.white),
                                  )
                                ]),
                          ],
                        ),
                      ),
                    ),
                    _session != null
                        ? _session!.questionsAllowed == 1
                        ? Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Oturum',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _session!.title ?? '',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8),
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'Konuşmacı',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _session?.speakerName ?? '',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  // Set background color to white
                                  borderRadius: BorderRadius.circular(
                                      10.0), // Make borders rounded
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        // Set background color to white
                                        borderRadius:
                                        BorderRadius.circular(
                                            10.0), // Make borders rounded
                                      ),
                                      child: Container(
                                        padding:
                                        const EdgeInsets.all(8),
                                        height: screenHeight * 0.3,
                                        child: TextField(
                                          maxLength: 255,
                                          decoration: const InputDecoration(
                                            hintText: 'Soru sor',
                                            border: InputBorder.none,
                                            counterText: "",
                                          ),
                                          maxLines: null,
                                          onChanged: (value) {
                                            setState(() {
                                              _question = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: screenHeight*0.01,
                                    ),
                                    Container(
                                      padding:
                                      const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        // Set background color to white
                                        borderRadius:
                                        BorderRadius.circular(
                                            10), // Make borders rounded
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: CheckboxListTile(
                                              title: Text(
                                                'İsmimi gizle',
                                                style: TextStyle(
                                                    color:
                                                    Colors.black),
                                              ),
                                              value: _isHiddenName,
                                              onChanged: (value) {
                                                setState(() {
                                                  _isHiddenName =
                                                  value!;
                                                });
                                              },
                                              controlAffinity:
                                              ListTileControlAffinity
                                                  .leading,
                                            ),
                                          ),
                                          Text(
                                            '${_question.length}/255',
                                            style: TextStyle(
                                              color: _question
                                                  .length <
                                                  140
                                                  ? Colors.green
                                                  : _question.length <
                                                  255
                                                  ? Colors.yellow
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: _question
                                          .length ==
                                          0
                                          ? CupertinoColors.systemGrey
                                          : AppConstants.buttonGreen,
                                      foregroundColor: Colors.white),
                                  onPressed: _asking
                                      ? null
                                      : () {
                                    if (_question.isNotEmpty &&
                                        _question.length <=
                                            256) {
                                      _askQuestion();
                                    }
                                  },
                                  child: _asking
                                      ? CircularProgressIndicator(
                                    valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                        Colors.white),
                                  )
                                      : Text('Gönder'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        : Padding(
                      padding: EdgeInsets.only(top: 20),
                          child: Text(
                                                'Bu Oturumda Soru alınmamaktadır',
                                                style: TextStyle(color: Colors.white, fontSize: 20),
                                              ),
                        )
                        : Padding(
                      padding: EdgeInsets.only(top: 20),
                          child: Text(
                                                'Oturum henüz başlamamıştır!',
                                                style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                                                ),
                                              ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _askQuestion() async {
    setState(() {
      _asking = true;
    });
    final url = Uri.parse(
        'https://app.kongrepad.com/api/v1/hall/${widget.hallId}/session-question');
    final body = jsonEncode({
      'question': _question,
      'is_hidden_name': _isHiddenName ? 1 : 0,
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
          content: "Sorunuz gönderildi!",
        );
        Navigator.of(context).pop();
      } else {
        AlertService().showAlertDialog(
          context,
          title: 'Hata',
          content: "Bir sorun meydana geldi!",
        );
      }
      setState(() {
        _asking = false;
      });
    }).catchError((error) {
      print(error);
      setState(() {
        _asking = false;
      });
    });
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
          _session = sessionJson.data;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
