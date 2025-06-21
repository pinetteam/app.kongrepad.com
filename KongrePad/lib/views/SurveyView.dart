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

      // ✅ YENİ: Önce survey'in cevaplanıp cevaplanmadığını kontrol et
      final surveyResult = await _surveyService.getSurveyDetails(
        survey!.id!,
        includeResults: true, // ✅ Cevapları da al
      );

      if (!mounted) return;

      if (surveyResult['success'] == true && surveyResult['data'] != null) {
        final surveyData = surveyResult['data'];
        print('SurveyView - Survey detayları alındı: ${surveyData['title']}');

        // ✅ YENİ: Survey'in cevaplanıp cevaplanmadığını kontrol et
        final participantStatus = surveyData['participant_status'];
        final hasParticipated = participantStatus?['has_participated'] ?? false;

        print('SurveyView - Survey cevaplanmış mı: $hasParticipated');

        // Eğer survey cevaplanmışsa, isEditable'i false yap
        if (hasParticipated) {
          setState(() {
            isEditable = false;
          });
          print('SurveyView - Survey zaten cevaplanmış, read-only mod');
        }

        // Questions'ı parse et
        if (surveyData['questions'] != null) {
          final questionsData = surveyData['questions'];

          // ✅ YENİ: Data formatını kontrol et
          if (questionsData is! List) {
            print(
                'SurveyView - Questions data List değil: ${questionsData.runtimeType}');
            setState(() {
              questions = [];
              _loading = false;
            });
            return;
          }

          final questionsList = <SurveyQuestion>[];

          for (final questionJson in questionsData) {
            try {
              // ✅ YENİ: JSON formatını kontrol et
              if (questionJson is! Map<String, dynamic>) {
                print(
                    'SurveyView - Question data Map değil: ${questionJson.runtimeType}');
                continue;
              }

              final question = SurveyQuestion.fromJson(questionJson);

              // ✅ YENİ: Question geçerliliğini kontrol et
              if (question.id == null) {
                print('SurveyView - Question ID null, atlanıyor');
                continue;
              }

              // ✅ YENİ: Eğer survey cevaplanmışsa, kullanıcının seçtiği option'ı işaretle
              if (hasParticipated &&
                  questionJson['selected_option_id'] != null) {
                final selectedOptionId = questionJson['selected_option_id'];
                question.selectedOption = selectedOptionId;
                selectedAnswers[question.id!] = selectedOptionId;
                print(
                    'SurveyView - Önceki cevap yüklendi: Question ${question.id}, Option $selectedOptionId');
              }

              questionsList.add(question);
              print(
                  'SurveyView - ✅ Question parse edildi: ${question.id} - ${question.question}');
            } catch (e, stackTrace) {
              print('SurveyView - Question parse hatası: $e');
              print('SurveyView - Question data: $questionJson');
              print('SurveyView - Stack trace: $stackTrace');

              // Hata durumunda kullanıcıya bilgi ver (sadece ilk hatada)
              if (questionsList.isEmpty && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bazı sorular yüklenirken hata oluştu'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          }

          if (!mounted) return;

          setState(() {
            questions = questionsList;
            _loading = false;
          });

          print('SurveyView - ✅ ${questionsList.length} soru yüklendi');

          // Pre-select stored answers (sadece edit modda)
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
          _errorMessage =
              surveyResult['message'] ?? 'Anket detayları yüklenemedi';
        });
        print(
            'SurveyView - Survey detayları yükleme başarısız: ${surveyResult['message']}');
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
        final storedAnswersString =
            prefs.getString('survey_${survey!.id}_answers');

        if (storedAnswersString != null && storedAnswersString.isNotEmpty) {
          print('SurveyView - Stored answers bulundu: $storedAnswersString');

          // JSON parse et
          final Map<String, dynamic> storedData =
              jsonDecode(storedAnswersString);

          // Answers'ı yükle
          if (storedData['selectedAnswers'] != null) {
            final Map<String, dynamic> selectedMap =
                storedData['selectedAnswers'];
            selectedAnswers = selectedMap
                .map((key, value) => MapEntry(int.parse(key), value as int));
            print(
                'SurveyView - ${selectedAnswers.length} stored answer yüklendi');
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

    print(
        'SurveyView - Answer selected: Question $questionId, Option $optionId');
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
          content: result['message'] ??
              'Anket başarıyla gönderildi. Katılımınız için teşekkürler!',
          onDismiss: () {
            Navigator.pop(context, true); // Return true to indicate success
          },
        );
      } else {
        print('SurveyView - Survey gönderme başarısız: ${result['message']}');

        // ✅ YENİ: Daha detaylı hata mesajları
        String errorMessage = result['message'] ?? 'Anket gönderilemedi';
        String errorTitle = 'Hata';
        bool showRetryButton = false;

        // Backend 500 hatası için özel mesaj
        if (errorMessage.contains('500') ||
            errorMessage.contains('INTERNAL_SERVER_ERROR')) {
          errorTitle = 'Sunucu Hatası';
          errorMessage =
              'Sunucuda geçici bir sorun oluştu. Lütfen birkaç dakika sonra tekrar deneyiniz.';
          showRetryButton = true;
        } else if (errorMessage.contains('401') ||
            errorMessage.contains('Unauthorized')) {
          errorTitle = 'Oturum Hatası';
          errorMessage = 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapınız.';
        } else if (errorMessage.contains('403') ||
            errorMessage.contains('Forbidden')) {
          errorTitle = 'Yetki Hatası';
          errorMessage = 'Bu ankete cevap verme yetkiniz bulunmuyor.';
        } else if (errorMessage.contains('409') ||
            errorMessage.contains('Conflict')) {
          errorTitle = 'Zaten Cevaplandı';
          errorMessage = 'Bu anketi daha önce cevaplamışsınız.';
        } else if (errorMessage.contains('422') ||
            errorMessage.contains('Validation')) {
          errorTitle = 'Geçersiz Veri';
          errorMessage =
              'Gönderilen veriler geçersiz. Lütfen kontrol edip tekrar deneyiniz.';
        }

        if (showRetryButton) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(errorTitle),
                content: Text(errorMessage),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      _submitSurvey(); // Retry
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('İptal'),
                  ),
                ],
              );
            },
          );
        } else {
          AlertService().showAlertDialog(
            context,
            title: errorTitle,
            content: errorMessage,
          );
        }
      }
    } catch (e) {
      print('SurveyView - Submit Exception: $e');
      if (mounted) {
        AlertService().showAlertDialog(
          context,
          title: 'Bağlantı Hatası',
          content: 'İnternet bağlantınızı kontrol edip tekrar deneyiniz.',
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
        'selectedAnswers': selectedAnswers
            .map((key, value) => MapEntry(key.toString(), value)),
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
                            question.question?.toString() ??
                                'Soru metni bulunamadı',
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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

        // ✅ YENİ: Read-only mod için renk seçimi
        Color optionColor;
        Color borderColor;
        Color textColor;

        if (isSelected) {
          if (isEditable) {
            optionColor = AppConstants.backgroundBlue.withOpacity(0.1);
            borderColor = AppConstants.backgroundBlue;
            textColor = AppConstants.backgroundBlue;
          } else {
            // Read-only modda seçili option'lar kırmızı olsun
            optionColor = Colors.red[50]!;
            borderColor = Colors.red[400]!;
            textColor = Colors.red[700]!;
          }
        } else {
          optionColor = Colors.grey[50]!;
          borderColor = Colors.grey[200]!;
          textColor = Colors.black87;
        }

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
                  color: optionColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
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
                        color: isSelected ? borderColor : Colors.transparent,
                        border: Border.all(
                          color: borderColor,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: isEditable ? Colors.white : Colors.white,
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
                          color: textColor,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // ✅ YENİ: Read-only modda seçili option'a işaret ekle
                    if (!isEditable && isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Colors.red[600],
                        size: 20,
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppConstants.backgroundBlue),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                              return _buildQuestionWidget(
                                  questions![index], index);
                            },
                          ),
          ),

          // Submit Button
          if (!_loading &&
              !_hasError &&
              questions != null &&
              questions!.isNotEmpty)
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
                child: isEditable
                    ? SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.buttonGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _sending ? null : _submitSurvey,
                          child: _sending
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Anketi Gönder',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.red[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bu anketi zaten cevapladınız',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
