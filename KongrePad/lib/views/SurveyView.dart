import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/Survey.dart';
import '../models/SurveyQuestion.dart';
import '../services/alert_service.dart';
import '../utils/app_constants.dart';
import 'SurveysView.dart';

class SurveyView extends StatefulWidget {
  const SurveyView({super.key, required this.survey, required this.isEditable});

  final Survey survey;
  final bool isEditable;

  @override
  State<SurveyView> createState() => _SurveyViewState(survey, isEditable);
}

class _SurveyViewState extends State<SurveyView> {
  Survey? survey;
  bool isEditable;

  List<SurveyQuestion>? questions;
  Set<int> answers = {};
  bool _sending = false;
  bool _loading = true;

  _SurveyViewState(this.survey, this.isEditable);

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final storedAnswers = prefs.getString('survey_${survey?.id}_answers');

    try {
      final url = Uri.parse(
          'https://app.kongrepad.com/api/v1/survey/${survey?.id}/question');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final questionsJson = SurveyQuestionsJSON.fromJson(jsonData);
        setState(() {
          questions = questionsJson.data;

          // Pre-select answers based on previous selections
          if (!isEditable && storedAnswers != null) {
            // Parse stored answers
            final List<int> previousAnswers =
                List<int>.from(jsonDecode(storedAnswers));

            for (var question in questions!) {
              for (var option in question.options!) {
                if (previousAnswers.contains(option.id)) {
                  option.isSelected = true;
                  answers.add(
                      option.id!); // Pre-select the user's previous answers
                }
              }
            }
          }

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
                color: AppConstants.backgroundBlue,
                height: screenHeight,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      height: screenHeight * 0.1,
                      decoration: const BoxDecoration(
                          color: AppConstants.backgroundBlue),
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
                                    survey!.title.toString(),
                                    style: const TextStyle(
                                        fontSize: 25, color: Colors.white),
                                  )
                                ]),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: screenHeight * 0.01,
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width: screenWidth,
                      height: screenHeight * 0.763,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          width: screenWidth,
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: questions != null
                                  ? questions!.map((question) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              question.question.toString(),
                                              textAlign: TextAlign.start,
                                              style: const TextStyle(
                                                  fontSize: 22,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            question.options?.length != 0
                                                ? Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: question.options!
                                                        .map((option) {
                                                      return RadioListTile<int>(
                                                        title: Text(
                                                          option.option
                                                              .toString(),
                                                          textAlign:
                                                              TextAlign.start,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 20,
                                                                  color: Colors
                                                                      .black),
                                                        ),
                                                        value: option.id!,
                                                        groupValue:
                                                            answers.contains(
                                                                    option.id)
                                                                ? option.id!
                                                                : null,
                                                        onChanged: isEditable
                                                            ? (int? value) {
                                                                setState(() {
                                                                  answers.removeWhere((id) => question
                                                                      .options!
                                                                      .any((o) =>
                                                                          o.id ==
                                                                          id));
                                                                  answers.add(
                                                                      value!);

                                                                  for (var o
                                                                      in question
                                                                          .options!) {
                                                                    o.isSelected =
                                                                        (o.id ==
                                                                            value);
                                                                  }
                                                                });
                                                              }
                                                            : null,
                                                      );
                                                    }).toList())
                                                : Container(),
                                            Container(
                                              width: double.infinity,
                                              height: screenHeight * 0.001,
                                              color: Colors.grey,
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList()
                                  : [],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: screenHeight * 0.1,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: AppConstants.backgroundBlue),
                      child: SizedBox(
                        height: screenHeight * 0.07,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEditable
                                ? AppConstants.buttonGreen
                                : Colors
                                    .grey, // Button is greyed out if survey is not editable
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12), // <-- Radius
                            ),
                          ),
                          onPressed: _sending ||
                                  !isEditable // Disable the send button if survey is not editable
                              ? null
                              : () {
                                  _sendAnswers();
                                },
                          child: _sending
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : Text(
                                  isEditable
                                      ? AppLocalizations.of(context)
                                          .translate('send_answers')
                                      : AppLocalizations.of(context).translate(
                                          'already_answered'), // Change button text if not editable
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ));
  }

  Future<void> _sendAnswers() async {
    setState(() {
      _sending = true;
    });

    if (answers.length != questions?.length) {
      AlertService().showAlertDialog(
        context,
        title: AppLocalizations.of(context).translate('warning'),
        content: AppLocalizations.of(context).translate('answers_required'),
      );
      setState(() {
        _sending = false;
      });
      return;
    }

    final url = Uri.parse(
        'https://app.kongrepad.com/api/v1/survey/${survey?.id!}/vote');
    final body = jsonEncode({
      'options': "[${answers.map((int e) => e.toString()).join(",")}]",
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${prefs.getString('token')}',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        // Store answers locally in SharedPreferences
        await prefs.setString(
            'survey_${survey?.id}_answers', jsonEncode(answers.toList()));

        AlertService().showAlertDialog(
          context,
          title: AppLocalizations.of(context).translate('success'),
          content: AppLocalizations.of(context).translate('thanks_message'),
          onDismiss: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SurveysView()),
            );
          },
        );
      } else {
        AlertService().showAlertDialog(
          context,
          title: AppLocalizations.of(context).translate('error'),
          content: AppLocalizations.of(context).translate('error_message'),
        );
      }
    } catch (error) {
      print(error);
      AlertService().showAlertDialog(
        context,
        title: AppLocalizations.of(context).translate('error'),
        content: AppLocalizations.of(context).translate('error_message'),
      );
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }
}
