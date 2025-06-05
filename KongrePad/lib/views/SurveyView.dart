import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../l10n/app_localizations.dart';
import '../models/Survey.dart';
import '../models/SurveyQuestion.dart';
import '../services/survey_service.dart';
import '../services/alert_service.dart';
import '../utils/app_constants.dart';

class SurveyView extends StatefulWidget {
  const SurveyView({super.key, required this.survey, required this.isEditable});

  final Survey survey;
  final bool isEditable;

  @override
  State<SurveyView> createState() => _SurveyViewState();
}

class _SurveyViewState extends State<SurveyView> {
  final SurveyService _surveyService = SurveyService();

  Survey? survey;
  late bool isEditable;
  List<SurveyQuestion>? questions;
  Map<int, int> selectedAnswers = {}; // questionId -> optionId
  bool _sending = false;
  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    survey = widget.survey;
    isEditable = widget.isEditable;
    _loadSurveyDetails();
  }

  Future<void> _loadSurveyDetails() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      print('SurveyView - Survey detayları yükleniyor, ID: ${survey?.id}');

      if (survey?.id == null) {
        throw Exception('Survey ID bulunamadı');
      }

      // Stored answers'ı yükle
      await _loadStoredAnswers();

      // SurveyService kullanarak survey detaylarını al
      final result = await _surveyService.getSurveyDetails(
        survey!.id!,
        includeResults: false,
      );

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final surveyData = result['data'];
        print('SurveyView - Survey detayları alındı: ${surveyData['title']}');

        // Questions'ı parse et
        if (surveyData['questions'] != null) {
          final questionsData = surveyData['questions'] as List;
          final questionsList = <SurveyQuestion>[];

          for (final questionJson in questionsData) {
            try {
              final question = SurveyQuestion.fromJson(questionJson);
              questionsList.add(question);
            } catch (e) {
              print('SurveyView - Question parse hatası: $e');
              print('SurveyView - Question data: $questionJson');
            }
          }

          setState(() {
            questions = questionsList;
            _loading = false;
          });

          print('SurveyView - ✅ ${questionsList.length} soru yüklendi');

          // Pre-select stored answers
          if (!isEditable) {
            _preselectStoredAnswers();
          }
        } else {
          setState(() {
            questions = [];
            _loading = false;
          });
          print('SurveyView - Questions field bulunamadı');
        }
      } else {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = result['message'] ?? 'Anket detayları yüklenemedi';
        });
        print('SurveyView - Survey detayları yükleme başarısız: ${result['message']}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Beklenmeyen hata: $e';
      });
      print('SurveyView - Exception: $e');
    }
  }

  Future<void> _loadStoredAnswers() async {
    if (!isEditable && survey?.id != null) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final storedAnswersString = prefs.getString('survey_${survey!.id}_answers');

        if (storedAnswersString != null && storedAnswersString.isNotEmpty) {
          print('SurveyView - Stored answers bulundu: $storedAnswersString');

          // JSON parse et
          final Map<String, dynamic> storedData = jsonDecode(storedAnswersString);

          // Answers'ı yükle
          if (storedData['selectedAnswers'] != null) {
            final Map<String, dynamic> selectedMap = storedData['selectedAnswers'];
            selectedAnswers = selectedMap.map((key, value) => MapEntry(int.parse(key), value as int));
            print('SurveyView - ${selectedAnswers.length} stored answer yüklendi');
          }
        }
      } catch (e) {
        print('SurveyView - Stored answers parse hatası: $e');
      }
    }
  }

  void _preselectStoredAnswers() {
    if (questions == null || selectedAnswers.isEmpty) return;

    for (var question in questions!) {
      if (question.id == null) continue;

      final selectedOptionId = selectedAnswers[question.id];
      if (selectedOptionId != null && question.options != null) {
        question.selectOption(selectedOptionId);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _selectAnswer(int questionId, int optionId) {
    if (!isEditable) return;

    setState(() {
      selectedAnswers[questionId] = optionId;

      // Update question selection state
      final question = questions?.firstWhere(
            (q) => q.id == questionId,
        orElse: () => SurveyQuestion(),
      );

      question?.selectOption(optionId);
    });

    print('SurveyView - Answer selected: Question $questionId, Option $optionId');
  }

  bool _validateAnswers() {
    if (questions == null || questions!.isEmpty) return false;

    for (var question in questions!) {
      if (question.id == null) continue;

      final questionId = question.id!;
      final isRequired = question.required ?? true;

      if (!isRequired) continue;

      // Sadece required soruları kontrol et
      if (!selectedAnswers.containsKey(questionId)) {
        return false;
      }
    }

    return true;
  }

  List<String> _getMissingRequiredQuestions() {
    final missing = <String>[];

    if (questions == null) return missing;

    for (var question in questions!) {
      if (question.id == null) continue;

      final questionId = question.id!;
      final isRequired = question.required ?? true;

      if (isRequired && !selectedAnswers.containsKey(questionId)) {
        missing.add(question.question ?? 'Soru #${missing.length + 1}');
      }
    }

    return missing;
  }

  void _showValidationError(List<String> missingQuestions) {
    if (!mounted) return;

    final message = missingQuestions.length == 1
        ? 'Şu zorunlu soruyu cevaplamanız gerekiyor:\n• ${missingQuestions.first}'
        : 'Şu zorunlu soruları cevaplamanız gerekiyor:\n${missingQuestions.map((q) => '• $q').join('\n')}';

    AlertService().showAlertDialog(
      context,
      title: 'Eksik Cevaplar',
      content: message,
    );
  }

  Future<void> _submitSurvey() async {
    final missingQuestions = _getMissingRequiredQuestions();

    if (missingQuestions.isNotEmpty) {
      _showValidationError(missingQuestions);
      return;
    }

    if (!mounted) return;

    setState(() {
      _sending = true;
    });

    try {
      print('SurveyView - Survey gönderiliyor...');

      // Responses'ı formatla
      final responses = SurveyService.formatChoiceResponses(selectedAnswers);

      print('SurveyView - Responses: $responses');

      // SurveyService kullanarak gönder
      final result = await _surveyService.submitSurvey(survey!.id!, responses);

      if (!mounted) return;

      if (result['success'] == true) {
        print('SurveyView - ✅ Survey başarıyla gönderildi');

        // Store answers locally - JSON formatında
        await _storeAnswersLocally();

        AlertService().showAlertDialog(
          context,
          title: 'Başarılı',
          content: result['message'] ?? 'Anket başarıyla gönderildi. Katılımınız için teşekkürler!',
          onDismiss: () {
            Navigator.pop(context, true); // Return true to indicate success
          },
        );
      } else {
        print('SurveyView - Survey gönderme başarısız: ${result['message']}');
        AlertService().showAlertDialog(
          context,
          title: 'Hata',
          content: result['message'] ?? 'Anket gönderilemedi',
        );
      }
    } catch (e) {
      print('SurveyView - Submit Exception: $e');
      if (mounted) {
        AlertService().showAlertDialog(
          context,
          title: 'Hata',
          content: 'Anket gönderilirken bir hata oluştu',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _storeAnswersLocally() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final answersData = {
        'selectedAnswers': selectedAnswers.map((key, value) => MapEntry(key.toString(), value)),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'completed': true,
      };

      await prefs.setString(
        'survey_${survey?.id}_answers',
        jsonEncode(answersData),
      );

      print('SurveyView - Answers stored locally');
    } catch (e) {
      print('SurveyView - Error storing answers locally: $e');
    }
  }

  Widget _buildQuestionWidget(SurveyQuestion question, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppConstants.backgroundBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Question text and required indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            question.question?.toString() ?? 'Soru metni bulunamadı',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (question.required == true)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[600],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Zorunlu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Question options
          _buildChoiceQuestion(question),
        ],
      ),
    );
  }

  Widget _buildChoiceQuestion(SurveyQuestion question) {
    if (!question.hasValidOptions) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
            const SizedBox(width: 12),
            Text(
              'Bu soru için seçenek bulunmuyor',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: question.options!.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = selectedAnswers[question.id] == option.id;
        final isLast = index == question.options!.length - 1;

        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isEditable && question.id != null
                  ? () => _selectAnswer(question.id!, option.id!)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.backgroundBlue.withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.backgroundBlue
                        : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Radio button
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppConstants.backgroundBlue
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppConstants.backgroundBlue
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Option text
                    Expanded(
                      child: Text(
                        option.option?.toString() ?? 'Seçenek metni bulunamadı',
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? AppConstants.backgroundBlue : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.backgroundBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.backgroundBlue),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Anket yükleniyor...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.backgroundBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lütfen bekleyin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadSurveyDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.backgroundBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Bu ankette soru bulunmuyor',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu anket henüz hazırlanmamış veya sorular yüklenemedi.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadSurveyDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.backgroundBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppConstants.backgroundBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: SvgPicture.asset(
                        'assets/icon/chevron.left.svg',
                        color: AppConstants.backgroundBlue,
                        height: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          survey?.title?.toString() ?? 'Anket',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (questions != null && questions!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${selectedAnswers.length}/${questions!.length} soru cevaplandı',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? _buildLoadingState()
                : _hasError
                ? _buildErrorState()
                : questions == null || questions!.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: questions!.length,
              itemBuilder: (context, index) {
                return _buildQuestionWidget(questions![index], index);
              },
            ),
          ),

          // Submit Button
          if (!_loading && !_hasError && questions != null && questions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditable
                          ? AppConstants.buttonGreen
                          : Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _sending || !isEditable ? null : _submitSurvey,
                    child: _sending
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEditable ? Icons.send : Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditable
                              ? 'Anketi Gönder'
                              : 'Zaten Cevaplandı',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}