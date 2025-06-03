import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_constants.dart';
import '../services/session_service.dart';

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
  String? _localPdfPath;
  List<Map<String, dynamic>>? _questions;
  final TextEditingController _questionController = TextEditingController();
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  String? _sessionTitle;
  String? _sessionDescription;

  Future<void> _downloadAndSavePdf() async {
    if (_pdfUrl == null) return;

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

      print('PDF kaydedildi: ${file.path}');

      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
        });
      }
    } catch (e) {
      print('PDF download hatası: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'PDF indirilemedi: $e';
          _loading = false;
        });
      }
    }
  }

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

      print('Session başlatılıyor - Hall ID: ${widget.hallId}');

      final streamData = await _sessionService.getSessionStream(widget.hallId);
      print('Stream data response: $streamData');

      if (streamData == null) {
        print('Stream data null geldi');
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Oturum bilgileri alınamadı';
        });
        return;
      }

      print('Stream data alındı: $streamData');

      setState(() {
        _pdfUrl = streamData['pdf_url'];
        _sessionTitle = streamData['title'];
        _sessionDescription = streamData['description'];
      });

      if (_pdfUrl != null) {
        print('PDF indirme başlıyor: $_pdfUrl');
        await _downloadAndSavePdf();
      }

      // Questions'ı yükle
      if (streamData['session_id'] != null) {
        final questions =
            await _sessionService.getSessionQuestions(widget.hallId);
        print('Questions response: $questions');

        if (mounted && questions != null) {
          setState(() {
            _questions = questions;
          });
        }
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

  Future<void> _askQuestion() async {
    if (_questionController.text.trim().isEmpty) return;

    try {
      final success = await _sessionService.askQuestion(
        widget.hallId,
        _questionController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context).translate('question_sent')),
              backgroundColor: Colors.green,
            ),
          );
          _questionController.clear();

          // Questions'ı yenile
          final questions =
              await _sessionService.getSessionQuestions(widget.hallId);
          if (mounted && questions != null) {
            setState(() {
              _questions = questions;
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context).translate('question_error')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Question gönderme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Soru gönderilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPdfViewer() {
    if (_pdfUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _sessionTitle ?? 'Oturum Bulunamadı',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _sessionDescription ?? 'Oturum bilgisi bulunamadı',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_localPdfPath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF yükleniyor...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
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
              print('PDF viewer hatası: $error');
              setState(() {
                _hasError = true;
                _errorMessage = 'PDF görüntülenirken hata oluştu: $error';
              });
            },
            onPageError: (page, error) {
              print('PDF sayfa hatası: $page - $error');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // PDF controller ayarları
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page ?? 0;
              });
            },
          ),
        ),
        if (_isReady)
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sayfa ${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Oturum yükleniyor...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Bir hata oluştu',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeSession,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // PDF Viewer
        Expanded(
          flex: 2,
          child: _buildPdfViewer(),
        ),
        // Questions Section
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    const Icon(Icons.question_answer, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sorular (${_questions?.length ?? 0})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _questions == null || _questions!.isEmpty
                    ? const Center(
                        child: Text(
                          'Henüz soru sorulmamış',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _questions!.length,
                        itemBuilder: (context, index) {
                          final question = _questions![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.help_outline),
                              title: Text(
                                question['question'] ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                question['participant']?['full_name'] ??
                                    'Anonim',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Question Input
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)
                              .translate('ask_question_hint'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: 2,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      onPressed: _askQuestion,
                      child: const Icon(Icons.send),
                    ),
                  ],
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('session')),
        backgroundColor: AppConstants.backgroundBlue,
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
    _questionController.dispose();
    super.dispose();
  }
}
