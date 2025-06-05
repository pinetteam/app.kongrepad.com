import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../l10n/app_localizations.dart';
import '../models/Survey.dart';
import '../services/survey_service.dart';
import '../utils/app_constants.dart';
import 'MainPageView.dart';
import 'SurveyView.dart';

class SurveysView extends StatefulWidget {
  const SurveysView({super.key});

  @override
  State<SurveysView> createState() => _SurveysViewState();
}

class _SurveysViewState extends State<SurveysView> {
  final SurveyService _surveyService = SurveyService();

  List<Survey>? surveys;
  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      print('SurveysView - Survey yükleme başladı');

      // Aktif survey'leri al
      final result = await _surveyService.getSurveys(
        status: 'active',
        limit: 50, // Sayfa başına maksimum survey sayısı
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final surveysData = result['data'] as List;
        print('SurveysView - ${surveysData.length} survey alındı');

        // Survey model'larına dönüştür
        final surveyList = <Survey>[];
        for (final surveyJson in surveysData) {
          try {
            final survey = Survey.fromJson(surveyJson);
            surveyList.add(survey);
          } catch (e) {
            print('SurveysView - Survey parse hatası: $e');
            print('SurveysView - Survey data: $surveyJson');
          }
        }

        setState(() {
          surveys = surveyList;
          _loading = false;
        });

        print('SurveysView - ✅ ${surveyList.length} survey başarıyla yüklendi');
      } else {
        setState(() {
          surveys = [];
          _loading = false;
          _hasError = true;
          _errorMessage = result['message'] ?? 'Anketler yüklenemedi';
        });
        print('SurveysView - Survey yükleme başarısız: ${result['message']}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        surveys = [];
        _loading = false;
        _hasError = true;
        _errorMessage = 'Beklenmeyen hata: $e';
      });
      print('SurveysView - Exception: $e');
    }
  }

  Future<void> _refreshSurveys() async {
    print('SurveysView - Refresh tetiklendi');
    await _loadSurveys();
  }

  void _navigateToSurvey(Survey survey) async {
    if (survey.id == null) {
      _showError('Geçersiz anket');
      return;
    }

    print('SurveysView - Survey tıklandı: ${survey.id} - ${survey.title}');

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SurveyView(
            survey: survey,
            isEditable: !(survey.isCompleted ?? false),
          ),
        ),
      );

      // Survey'den geri dönüldüğünde liste güncelle
      if (result == true) {
        print('SurveysView - Survey tamamlandı, liste güncelleniyor');
        await _refreshSurveys();
      }
    } catch (e) {
      print('SurveysView - Navigation hatası: $e');
      _showError('Anket açılırken hata oluştu: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSurveyCard(Survey survey) {
    final isCompleted = survey.isCompleted ?? false;
    final hasTitle = survey.title?.isNotEmpty == true;
    final hasDescription = survey.description?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          color: isCompleted ? Colors.green[600] : AppConstants.buttonDarkBlue,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToSurvey(survey),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Survey icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgPicture.asset(
                      isCompleted
                          ? 'assets/icon/checklist.checked.svg'
                          : 'assets/icon/checklist.svg',
                      color: Colors.white,
                      height: 28,
                      width: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Survey content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          hasTitle ? survey.title! : 'İsimsiz Anket',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Description
                        if (hasDescription) ...[
                          const SizedBox(height: 8),
                          Text(
                            survey.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Status
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (isCompleted) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Tamamlandı',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Bekliyor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
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
                Icons.poll_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Henüz anket bulunmuyor',
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Şu anda katılabileceğiniz aktif bir anket yok.\nYeni anketler için bu sayfayı kontrol edin.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshSurveys,
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.backgroundBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshSurveys,
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
          ],
        ),
      ),
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
            'Anketler yükleniyor...',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainPageView(title: ''),
                        ),
                      );
                    },
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
                    child: Text(
                      AppLocalizations.of(context).translate('surveys'),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: _refreshSurveys,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? _buildLoadingState()
                  : _hasError
                  ? _buildErrorState()
                  : surveys == null || surveys!.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _refreshSurveys,
                color: AppConstants.backgroundBlue,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: surveys!.length,
                  itemBuilder: (context, index) {
                    final survey = surveys![index];
                    return _buildSurveyCard(survey);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}