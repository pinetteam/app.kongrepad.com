import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/question_service.dart';
import '../utils/app_constants.dart';
import '../services/auth_service.dart';

class AskQuestionView extends StatefulWidget {
  final int hallId; // Bu aslında sessionId olarak kullanılacak

  const AskQuestionView({super.key, required this.hallId});

  @override
  _AskQuestionViewState createState() => _AskQuestionViewState();
}

class _AskQuestionViewState extends State<AskQuestionView> {
  final QuestionService _questionService = QuestionService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>>? _questions;
  final TextEditingController _questionController = TextEditingController();
  bool _isAnonymous = false;
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _sending = false;
  String? _sessionTitle;
  int? _realSessionId; // ✅ YENİ: Gerçek session ID'yi sakla

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Session title'ı arguments'tan al
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _sessionTitle = args['sessionTitle'];
          _realSessionId =
              args['realSessionId']; // ✅ YENİ: Gerçek session ID'yi al
        });
      }

      // ✅ YENİ: Önce gerçek session ID'yi bul
      await _findRealSessionId();

      // DEBUG: Endpoint'leri test et
      final sessionIdToTest = _realSessionId ?? widget.hallId;
      await _questionService.debugCurrentEndpoints(sessionIdToTest);

      // Normal soru yükleme işlemini başlat
      _getQuestions();
    });
  }

  // ✅ YENİ: Gerçek session ID'yi bul
  Future<void> _findRealSessionId() async {
    try {
      print(
          'AskQuestionView - Gerçek session ID aranıyor, Hall ID: ${widget.hallId}');

      final token = await _authService.getStoredToken();
      if (token == null) return;

      // Current activities'den live sessions'ları al
      final response = await http.get(
        Uri.parse('https://api.kongrepad.com/api/v1/meetings/current'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final meetingData = jsonDecode(response.body);
        final currentActivities = meetingData['data']?['current_activities'];

        if (currentActivities != null &&
            currentActivities['live_sessions'] != null) {
          final liveSessionsData = currentActivities['live_sessions'];
          List liveSessions;

          if (liveSessionsData is Map) {
            liveSessions = liveSessionsData.values.toList();
          } else if (liveSessionsData is List) {
            liveSessions = liveSessionsData;
          } else {
            liveSessions = [];
          }

          // Bu hall ID'ye ait session'ı bul
          for (var session in liveSessions) {
            final sessionHallId = session['program']?['hall_id'];
            final sessionId = session['id'];

            if (sessionHallId == widget.hallId) {
              print(
                  'AskQuestionView - ✅ Gerçek session ID bulundu: $sessionId (Hall ID: $sessionHallId)');
              setState(() {
                _realSessionId = sessionId;
              });
              return;
            }
          }

          print(
              'AskQuestionView - ❌ Hall ID ${widget.hallId} için session bulunamadı');
        }
      }
    } catch (e) {
      print('AskQuestionView - Session ID bulma hatası: $e');
    }
  }

  Future<void> _getQuestions() async {
    final sessionId = _realSessionId ?? widget.hallId;
    print(
        'AskQuestionView - _getQuestions başladı, sessionId: $sessionId (Hall ID: ${widget.hallId})');

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final questions = await _questionService.getSessionQuestions(sessionId);

      if (mounted) {
        setState(() {
          _questions = questions ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      print('AskQuestionView - Questions yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _questions = [];
          _loading = false;
          _hasError = true;
          _errorMessage = 'Sorular yüklenirken hata oluştu';
        });
      }
    }
  }

  // ✅ YENİ: Enrollment kontrol dialog'u
  Future<void> _showEnrollmentDialog(String message, String reason) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppConstants.backgroundBlue),
            SizedBox(width: 8),
            Text('Kayıt Gerekli'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (reason == 'not_enrolled') ...[
              SizedBox(height: 12),
              Text(
                'Etkinliğe kayıt olmak için aşağıdaki butona tıklayın.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          if (reason == 'not_enrolled' || reason == 'no_gdpr_consent') ...[
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performEnrollment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.backgroundBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Kayıt Ol'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: Text('Tamam'),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ YENİ: Enrollment işlemi
  Future<void> _performEnrollment() async {
    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Kayıt olunuyor...'),
          ],
        ),
      ),
    );

    try {
      final success = await _authService.enrollParticipant(gdprConsent: true);

      Navigator.pop(context); // Loading dialog'u kapat

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Başarıyla kayıt oldunuz!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showErrorMessage(
            'Kayıt işlemi başarısız oldu. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      Navigator.pop(context); // Loading dialog'u kapat
      print('Enrollment error: $e');
      _showErrorMessage('Kayıt işlemi sırasında hata oluştu.');
    }
  }

  Future<void> _askQuestion() async {
    final questionText = _questionController.text.trim();

    // ✅ YENİ: Frontend validation
    if (questionText.isEmpty) {
      _showErrorMessage('Lütfen bir soru yazın');
      return;
    }

    if (questionText.length < 10) {
      _showErrorMessage('Soru en az 10 karakter olmalıdır');
      return;
    }

    // ✅ YENİ: Önce enrollment durumunu kontrol et
    final enrollmentStatus = await _authService.checkEnrollmentStatus();

    if (enrollmentStatus['needs_enrollment'] == true) {
      final reason = enrollmentStatus['reason'] ?? 'unknown';
      final message = enrollmentStatus['message'] ?? 'Kayıt gerekli';

      print('AskQuestionView - Enrollment gerekli: $reason');
      await _showEnrollmentDialog(message, reason);
      return;
    }

    if (enrollmentStatus['can_participate'] != true) {
      final message = enrollmentStatus['message'] ?? 'Katılım izni yok';
      print('AskQuestionView - Katılım izni yok: $message');
      _showErrorMessage(message);
      return;
    }

    final sessionId = _realSessionId ?? widget.hallId;
    print('AskQuestionView - Soru gönderiliyor, sessionId: $sessionId');

    setState(() {
      _sending = true;
    });

    try {
      final success = await _questionService.askQuestion(
        sessionId,
        questionText, // ✅ Temizlenmiş text kullan
        anonymous: _isAnonymous,
      );

      if (mounted) {
        if (success) {
          _questionController.clear();
          setState(() {
            _isAnonymous = false;
          });

          // Success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Sorunuz başarıyla gönderildi!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              duration: Duration(seconds: 3),
            ),
          );

          // Soruları yenile
          await _getQuestions();

          // SessionView'a başarı bilgisi döndür
          Navigator.pop(context, true);
        } else {
          _showErrorMessage('Bu oturum şu anda aktif değil');
        }
      }
    } catch (e) {
      print('Soru gönderme hatası: $e');
      if (mounted) {
        _showErrorMessage('Bağlantı hatası oluştu');
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ✅ YENİ: Button state kontrolü
  Widget _buildQuestionInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText:
                    'Sorunuzu yazın (en az 10 karakter)...', // ✅ YENİ: Hint güncellendi
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                // ✅ YENİ: Karakter sayacı ekle
                helperText:
                    '${_questionController.text.length}/10 karakter minimum',
                helperStyle: TextStyle(
                  color: _questionController.text.length >= 10
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 12,
                ),
              ),
              maxLines: 4,
              minLines: 2,
              onChanged: (value) {
                setState(() {}); // Button state ve counter güncelle
              },
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Checkbox(
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          _isAnonymous = value ?? false;
                        });
                      },
                      activeColor: AppConstants.backgroundBlue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Expanded(
                      child: Text(
                        'Anonim olarak sor',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  // ✅ YENİ: Minimum karakter kontrolü eklendi
                  onPressed:
                      _sending || _questionController.text.trim().length < 10
                          ? null
                          : _askQuestion,
                  icon: _sending
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.send, size: 16),
                  label: Text(
                    _sending ? 'Gönder...' : 'Gönder',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.backgroundBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Sorular yükleniyor...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getQuestions,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_questions == null || _questions!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Henüz soru sorulmamış',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'İlk soruyu sormak için aşağıdaki formu kullanın',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _questions!.length,
      itemBuilder: (context, index) {
        final question = _questions![index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        AppConstants.backgroundBlue.withOpacity(0.1),
                    child: Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppConstants.backgroundBlue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question['participant']?['full_name'] ?? 'Anonim',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.backgroundBlue,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                question['question'] ?? '',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundBlue,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundBlue,
        title: Text(
          _sessionTitle ?? 'Soru Sor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _getQuestions,
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildQuestionsList()),
            _buildQuestionInput(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}
