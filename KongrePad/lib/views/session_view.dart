import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import '../services/session_service.dart';
import '../widgets/pdf_viewer_widget.dart';

class SessionView extends StatefulWidget {
  final int hallId;

  const SessionView({Key? key, required this.hallId}) : super(key: key);

  @override
  State<SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<SessionView> {
  final SessionService _sessionService = SessionService();

  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _pdfUrl;
  String? _sessionTitle;
  String? _sessionDescription;
  int? _sessionId;
  String? _fileName;
  bool _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
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
          _errorMessage =
              'Hall ID ${widget.hallId} için oturum bilgileri alınamadı';
        });
        return;
      }

      setState(() {
        _pdfUrl = sessionData['pdf_url'];
        _sessionTitle = sessionData['title'] ?? 'Oturum';
        _sessionDescription =
            sessionData['description'] ?? 'Oturum açıklaması mevcut değil';
        _fileName = sessionData['file_name'] ?? 'Doküman';

        if (sessionData['session_id'] != null) {
          try {
            _sessionId = int.parse(sessionData['session_id'].toString());
          } catch (e) {
            _sessionId = null;
          }
        }

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Oturum yüklenirken hata oluştu: ${e.toString()}';
      });
    }
  }

  void _navigateToAskQuestion() {
    if (_sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aktif oturum bulunamadı. Hall ID: ${widget.hallId}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Yenile',
            textColor: Colors.white,
            onPressed: _initializeSession,
          ),
        ),
      );
      return;
    }

    final arguments = <String, dynamic>{
      'hallId': widget.hallId,
      'sessionTitle': _sessionTitle ?? 'Oturum',
      'realSessionId': _sessionId,
    };

    print(
        'SessionView - AskQuestionView\'a yönlendiriliyor: Hall ID=${widget.hallId}, Real Session ID=$_sessionId');

    Navigator.pushNamed(context, '/ask-question', arguments: arguments);
  }

  Future<void> _downloadAndShowPdf() async {
    if (_pdfUrl == null) return;

    setState(() {
      _pdfLoading = true;
    });

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse(_pdfUrl!),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf, application/octet-stream, */*',
        },
      );

      if (response.statusCode == 200) {
        _showPdfViewer(response.bodyBytes);
      } else if (response.statusCode == 403) {
        throw Exception('Erişim yasak (403): PDF indirme izni yok');
      } else {
        throw Exception('PDF indirme hatası: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF indirilemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _pdfLoading = false;
      });
    }
  }

  void _showPdfViewer(List<int> pdfBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          pdfBytes: pdfBytes,
          title: _sessionTitle ?? 'Oturum Dokümanı',
          fileName: _fileName ?? 'Doküman',
        ),
      ),
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppConstants.backgroundBlue),
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // PDF Viewer Section
        Expanded(
          child: _buildPdfSection(),
        ),
        // Ask Question Button
        if (_sessionId != null)
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToAskQuestion,
                icon: const Icon(Icons.help_outline, size: 20),
                label: const Text(
                  'Soru Sor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.backgroundBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPdfSection() {
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeSession,
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.backgroundBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.backgroundBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: AppConstants.backgroundBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _sessionTitle ?? 'Oturum Dokümanı',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _fileName ?? 'PDF Dokümanı',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Text(
              'PDF Mevcut',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pdfLoading ? null : _downloadAndShowPdf,
              icon: _pdfLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf, size: 20),
              label: Text(_pdfLoading ? 'Yükleniyor...' : 'PDF\'i Görüntüle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.backgroundBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ✅ TEST BUTONU
          ElevatedButton.icon(
            onPressed: () async {
              print(
                  'SessionView - Token ile PDF endpoint test başlatılıyor...');
              await _sessionService.testPdfEndpointWithToken();
            },
            icon: const Icon(Icons.bug_report, size: 20),
            label: const Text('PDF Endpoint Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 1,
            ),
          ),
          Text(
            'PDF uygulama içinde görüntülenecek',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
}
