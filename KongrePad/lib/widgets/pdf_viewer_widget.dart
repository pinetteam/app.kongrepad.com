import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class PdfViewerWidget extends StatefulWidget {
  final List<int> pdfBytes;
  final Function(int page, int total)? onPageChanged;

  const PdfViewerWidget({
    Key? key,
    required this.pdfBytes,
    this.onPageChanged,
  }) : super(key: key);

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  String? _localPath;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _createLocalFile();
  }

  Future<void> _createLocalFile() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/temp_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(widget.pdfBytes);

      setState(() {
        _localPath = file.path;
      });
    } catch (e) {
      print('PDF dosya oluşturma hatası: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    // Geçici dosyayı sil
    if (_localPath != null) {
      try {
        File(_localPath!)
            .delete()
            .catchError((e) => print('Temp file deletion error: $e'));
      } catch (e) {
        print('Dispose error: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'PDF yüklenirken hata oluştu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_localPath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'PDF hazırlanıyor...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // PDF Page Counter
        if (_isReady && _totalPages > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sayfa ${_currentPage + 1} / $_totalPages',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_totalPages > 1)
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            _currentPage > 0 ? () => _previousPage() : null,
                        icon: Icon(
                          Icons.keyboard_arrow_left,
                          color: _currentPage > 0 ? Colors.blue : Colors.grey,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        onPressed: _currentPage < _totalPages - 1
                            ? () => _nextPage()
                            : null,
                        icon: Icon(
                          Icons.keyboard_arrow_right,
                          color: _currentPage < _totalPages - 1
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        // PDF Viewer
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages ?? 0;
                  _isReady = true;
                });
                print('PDF rendered with $_totalPages pages');
              },
              onError: (error) {
                print('PDF error: $error');
                setState(() {
                  _hasError = true;
                });
              },
              onPageError: (page, error) {
                print('PDF page error: $page - $error');
              },
              onViewCreated: (PDFViewController controller) {
                print('PDF view created');
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page ?? 0;
                  _totalPages = total ?? 0;
                });
                widget.onPageChanged?.call(_currentPage, _totalPages);
                print('PDF page changed: $_currentPage / $_totalPages');
              },
            ),
          ),
        ),
      ],
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      // PDFView controller'ını kullanarak sayfa değiştirme
      // Bu özellik flutter_pdfview paketinin versiyonuna bağlı
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      // PDFView controller'ını kullanarak sayfa değiştirme
      // Bu özellik flutter_pdfview paketinin versiyonuna bağlı
    }
  }
}
