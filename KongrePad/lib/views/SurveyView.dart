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

    print('SurveyView - getData başladı, Survey ID: ${survey?.id}');
    print('SurveyView - Token: ${token?.substring(0, 10)}...');

    try {
      // ✅ Doğru URL - Swagger'a göre güncellendi
      final url = Uri.parse('https://api.kongrepad.com/api/v1/surveys/${survey?.id}');
      print('SurveyView - Request URL: $url');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('SurveyView - Response Status: ${response.statusCode}');
      print('SurveyView - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('SurveyView - JSON Data Keys: ${jsonData.keys}');

        // API response yapısını kontrol et
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final surveyData = jsonData['data'];
          print('SurveyView - Survey Data Keys: ${surveyData.keys}');

          // Questions'ı bul
          if (surveyData['questions'] != null) {
            final questionsJson = SurveyQuestionsJSON.fromJson({'data': surveyData['questions']});

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

            print('SurveyView - ${questions?.length} question bulundu');
          } else {
            print('SurveyView - Questions field bulunamadı');
            setState(() {
              questions = [];
              _loading = false;
            });
          }
        } else {
          print('SurveyView - API success=false veya data=null');
          print('SurveyView - Message: ${jsonData['message']}');
          setState(() {
            _loading = false;
          });
        }
      } else if (response.statusCode == 401) {
        print('SurveyView - Unauthorized (401)');
        setState(() {
          _loading = false;
        });
      } else {
        print('SurveyView - HTTP Error: ${response.statusCode}');
        print('SurveyView - Error Body: ${response.body}');
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('SurveyView - Exception Error: $e');
      setState(() {
        _loading = false;
      });
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
                            Expanded(
                              child: Text(
                                survey!.title.toString(),
                                style: const TextStyle(
                                    fontSize: 25, color: Colors.white),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                child: questions == null || questions!.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bu ankette henüz soru bulunmuyor',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                          });
                          getData();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yenile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.backgroundBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                    : SingleChildScrollView(
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
                        children: questions!.map((question) {
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
                                const SizedBox(height: 8),
                                if (question.options != null && question.options!.isNotEmpty)
                                  Column(
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
                                else
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'Bu soru için henüz seçenek bulunmuyor',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: double.infinity,
                                  height: screenHeight * 0.001,
                                  color: Colors.grey,
                                )
                              ],
                            ),
                          );
                        }).toList(),
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
                        !isEditable ||
                        questions == null ||
                        questions!.isEmpty // Disable the send button if survey is not editable
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

    // ✅ Doğru URL - Swagger'a göre güncellendi
    final url = Uri.parse(
        'https://api.kongrepad.com/api/v1/surveys/${survey?.id!}/submit');

    print('SurveyView - Submit URL: $url');
    print('SurveyView - Answers: $answers');

    final body = jsonEncode({
      'options': "[${answers.map((int e) => e.toString()).join(",")}]",
    });

    print('SurveyView - Submit Body: $body');

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${prefs.getString('token')}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      print('SurveyView - Submit Response Status: ${response.statusCode}');
      print('SurveyView - Submit Response Body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      // API response yapısını kontrol et
      if (jsonResponse['success'] == true || jsonResponse['status'] == true) {
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
        print('SurveyView - Submit failed: ${jsonResponse['message']}');
        AlertService().showAlertDialog(
          context,
          title: AppLocalizations.of(context).translate('error'),
          content: jsonResponse['message'] ?? AppLocalizations.of(context).translate('error_message'),
        );
      }
    } catch (error) {
      print('SurveyView - Submit Exception: $error');
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