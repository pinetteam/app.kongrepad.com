import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_constants.dart';
import '../services/session_service.dart';
import '../services/question_service.dart';

class SessionView extends StatefulWidget {
  final int hallId;

  const SessionView({Key? key, required this.hallId}) : super(key: key);

  @override
  State<SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<SessionView> {
  final SessionService _sessionService = SessionService();
  final QuestionService _questionService = QuestionService();

  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _pdfUrl;
  String? _localPdfPath;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  String? _sessionTitle;
  String? _sessionDescription;
  int? _sessionId;
  bool _isPdfDownloading = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _downloadAndSavePdf() async {
    if (_pdfUrl == null) return;

    setState(() {
      _isPdfDownloading = true;
    });

    try {
      print('PDF indiriliyor: $_pdfUrl');
      final response = await http.get(Uri.parse(_pdfUrl!));

      if (response.statusCode != 200) {
        throw Exception('PDF indirilemedi: ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/session_document_${widget.hallId}.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
          _isPdfDownloading = false;
        });
      }
    } catch (e) {
      print('PDF download hatası: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'PDF indirilemedi: $e';
          _loading = false;
          _isPdfDownloading = false;
        });
      }
    }
  }

  Future<void> _initializeSession() async {
    try {
      setState(() {
        _loading = true;
        _hasError = false;
        _errorMessage = null;
      });

      final sessionData = await _sessionService.getActiveSession(widget.hallId);

      if (sessionData == null) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Oturum bilgileri alınamadı';
        });
        return;
      }

      setState(() {
        _pdfUrl = sessionData['pdf_url'];
        _sessionTitle = sessionData['title'];
        _sessionDescription = sessionData['description'];
        _sessionId = sessionData['session_id'] != null
            ? int.parse(sessionData['session_id'].toString())
            : null;
      });

      if (_pdfUrl != null) {
        await _downloadAndSavePdf();
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Session initialization hatası: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Oturum yüklenirken bir hata oluştu: $e';
        });
      }
    }
  }

  void _navigateToAskQuestion() {
    print('Soru Sor butonuna tıklandı - Session ID: $_sessionId');

    if (_sessionId == null) {
      print('Session ID null, soru sorma sayfasına gidemez');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oturum bilgisi bulunamadı. Lütfen sayfayı yenileyin.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Session ID'yi hallId olarak geçir (AskQuestionView sessionId ile çalışacak)
    Navigator.pushNamed(
      context,
      '/ask-question',
      arguments: {
        'hallId': _sessionId, // Session ID'yi hallId olarak geçir
        'sessionTitle': _sessionTitle,
      },
    ).then((result) {
      print('AskQuestionView\'den döndü, result: $result');
      if (result == true) {
        // Soru başarılı bir şekilde gönderildi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sorunuz başarıyla gönderildi!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }).catchError((error) {
      print('Navigation hatası: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Soru sorma sayfası bulunamadı. Route tanımlanmamış.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  Widget _buildPdfViewer() {
    if (_pdfUrl == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _sessionTitle ?? 'Oturum Bulunamadı',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _sessionDescription ?? 'Bu oturum için doküman bulunmuyor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_isPdfDownloading || _localPdfPath == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.backgroundBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.backgroundBlue),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PDF Yükleniyor...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.backgroundBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Doküman indiriliyor, lütfen bekleyin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // PDF Info Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppConstants.backgroundBlue.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: AppConstants.backgroundBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _sessionTitle ?? 'Oturum Dokümanı',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.backgroundBlue,
                  ),
                ),
              ),
              if (_isReady)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // PDF Viewer
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: PDFView(
              filePath: _localPdfPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              defaultPage: _currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages!;
                  _isReady = true;
                });
              },
              onError: (error) {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'PDF görüntülenirken hata oluştu: $error';
                });
              },
              onPageError: (page, error) {
                print('PDF sayfa hatası: $page - $error');
              },
              onViewCreated: (PDFViewController pdfViewController) {
                print('PDF viewer oluşturuldu');
              },
              onPageChanged: (int? page, int? total) {
                setState(() {
                  _currentPage = page ?? 0;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.backgroundBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.backgroundBlue),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oturum yükleniyor...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.backgroundBlue,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bir hata oluştu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Bilinmeyen hata',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeSession,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.backgroundBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

    return Column(
      children: [
        // PDF Viewer
        Expanded(
          child: _buildPdfViewer(),
        ),
        // Ask Question Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[200]!,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Debug info (sadece development için)
              if (_sessionId != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Session ID: $_sessionId ✓',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('Buton tıklandı! Session ID: $_sessionId');
                    _navigateToAskQuestion();
                  },
                  icon: const Icon(Icons.help_outline, size: 20),
                  label: const Text(
                    'Soru Sor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sessionId != null
                        ? AppConstants.backgroundBlue
                        : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _sessionTitle ?? 'Oturum',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstants.backgroundBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_localPdfPath != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initializeSession,
              tooltip: 'Yenile',
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}