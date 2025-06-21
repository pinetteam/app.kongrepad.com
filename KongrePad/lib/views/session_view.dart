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
  List<int>? _pdfBytes;
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
        _pdfBytes = null;
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
      });

      // PDF varsa direkt yükle
      if (_pdfUrl != null) {
        await _loadPdf();
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Oturum yüklenirken hata oluştu: ${e.toString()}';
      });
    }
  }

  Future<void> _loadPdf() async {
    if (_pdfUrl == null) return;

    try {
      setState(() {
        _pdfLoading = true;
      });

      final token = await AuthService().getStoredToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      print('PDF yükleniyor: $_pdfUrl');

      final response = await http.get(
        Uri.parse(_pdfUrl!),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf, application/octet-stream, */*',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _pdfBytes = response.bodyBytes;
          _loading = false;
          _pdfLoading = false;
        });
        print('PDF başarıyla yüklendi: ${response.bodyBytes.length} bytes');
      } else {
        throw Exception('PDF yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('PDF yükleme hatası: $e');
      setState(() {
        _loading = false;
        _pdfLoading = false;
        _hasError = true;
        _errorMessage = 'PDF yüklenirken hata oluştu: ${e.toString()}';
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

    Navigator.pushNamed(context, '/ask-question', arguments: arguments);
  }

  Widget _buildLoadingState() {
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppConstants.backgroundBlue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _pdfLoading ? 'PDF yükleniyor...' : 'Oturum yükleniyor...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.backgroundBlue,
            ),
          ),
          if (_pdfLoading) ...[
            const SizedBox(height: 12),
            Text(
              'Doküman hazırlanıyor',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPdfState() {
    return Container(
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
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _sessionTitle ?? 'Oturum',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Text(
              'Doküman bulunmuyor',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _sessionDescription ?? 'Bu oturum için henüz doküman yüklenmemiş',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _initializeSession,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Yenile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.backgroundBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // PDF Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundBlue.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: AppConstants.backgroundBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName ?? 'Doküman',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Text(
                          'Hazır',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // PDF Content
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: PdfViewerWidget(
                pdfBytes: _pdfBytes!,
                onPageChanged: (page, total) {
                  // Sayfa değişikliği burada handle edilebilir
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_pdfBytes != null) {
      return _buildPdfViewer();
    } else {
      return _buildNoPdfState();
    }
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
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: _buildContent(),
          ),
          // Ask Question Button (Always at bottom if session exists)
          if (_sessionId != null && !_loading)
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
      ),
    );
  }
}
