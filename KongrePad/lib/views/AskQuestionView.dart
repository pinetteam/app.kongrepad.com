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

      final token = await AuthService().getStoredToken();
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

  Future<void> _askQuestion() async {
    if (_questionController.text.trim().isEmpty) return;

    final sessionId = _realSessionId ?? widget.hallId;
    print('AskQuestionView - Soru gönderiliyor, sessionId: $sessionId');

    setState(() {
      _sending = true;
    });

    try {
      final success = await _questionService.askQuestion(
        sessionId, // ✅ YENİ: Gerçek session ID'yi kullan
        _questionController.text.trim(),
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
                hintText: 'Sorunuzu yazın...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 4,
              minLines: 2,
              onChanged: (value) {
                setState(() {}); // Button state güncelle
              },
            ),
          ),
          SizedBox(height: 12),
          // ✅ TAŞMA SORUNU ÇÖZÜLDİ - Responsive Row Layout
          Row(
            children: [
              // Checkbox ve text için flex alan
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
                      // ✅ Flexible yerine Expanded - TAŞMA ÇÖZÜLDÜ
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
              // Button için sabit alan
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _sending || _questionController.text.trim().isEmpty
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
