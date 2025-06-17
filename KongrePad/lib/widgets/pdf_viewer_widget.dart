import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_constants.dart';

class PdfViewerPage extends StatefulWidget {
  final List<int> pdfBytes;
  final String title;
  final String fileName;

  const PdfViewerPage({
    Key? key,
    required this.pdfBytes,
    required this.title,
    required this.fileName,
  }) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  File? _pdfFile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _saveAndLoadPdf();
  }

  Future<void> _saveAndLoadPdf() async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${widget.fileName}.pdf');
      await file.writeAsBytes(widget.pdfBytes);

      setState(() {
        _pdfFile = file;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'PDF yüklenirken hata oluştu: $e';
        _loading = false;
      });
    }
  }

  void _showPdfInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosya Adı: ${widget.fileName}'),
            const SizedBox(height: 8),
            Text(
                'Boyut: ${(widget.pdfBytes.length / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 8),
            Text('Format: PDF'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
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
            'PDF Yüklenemedi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveAndLoadPdf,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    if (_pdfFile == null) {
      return const Center(child: Text('PDF dosyası bulunamadı'));
    }

    return PDFView(
      filePath: _pdfFile!.path,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) => print('PDF rendered with $pages pages'),
      onError: (error) {
        print('PDF error: $error');
        setState(() {
          _error = 'PDF görüntülenirken hata oluştu: $error';
        });
      },
      onPageError: (page, error) =>
          print('PDF page error on page $page: $error'),
      onViewCreated: (controller) => print('PDF view created'),
      onPageChanged: (page, total) => print('PDF page changed: $page / $total'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppConstants.backgroundBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showPdfInfo,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildPdfView(),
    );
  }
}
