import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../Models/VirtualStand.dart';
import '../utils/app_constants.dart';

class VirtualStandView extends StatefulWidget {
  const VirtualStandView({super.key, required this.stand});

  final VirtualStand stand;

  @override
  State<VirtualStandView> createState() => _VirtualStandViewState(stand);
}

class _VirtualStandViewState extends State<VirtualStandView> {
  final VirtualStand stand;
  bool _loading = true;
  String? _localPdfPath;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      final url =
          'https://app.kongrepad.com/storage/virtual-stand-pdfs/${stand.pdfName}.pdf';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('PDF indirilemedi: ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/virtual_stand_${stand.id}.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'PDF yüklenirken bir hata oluştu: $e';
          _loading = false;
        });
      }
    }
  }

  Widget _buildPdfViewer() {
    if (_loading) {
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

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _downloadAndSavePdf,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_localPdfPath == null) {
      return const Center(
        child: Text('PDF bulunamadı'),
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
            onRender: (pages) {
              setState(() {
                _totalPages = pages!;
              });
            },
            onError: (error) {
              setState(() {
                _errorMessage = 'PDF görüntülenirken hata oluştu: $error';
              });
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page ?? 0;
              });
            },
          ),
        ),
        if (_totalPages > 0)
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

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              height: screenHeight * 0.1,
              decoration:
                  const BoxDecoration(color: AppConstants.virtualStandBlue),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: screenHeight * 0.05,
                      width: screenHeight * 0.05,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.logoutButtonBlue,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          'assets/icon/chevron.left.svg',
                          color: Colors.white,
                          height: screenHeight * 0.03,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Image.network(
                      'https://app.kongrepad.com/storage/virtual-stands/${stand.fileName}.${stand.fileExtension}',
                      width: 150,
                      height: screenHeight * 0.08,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: screenHeight * 0.85,
              child: _buildPdfViewer(),
            ),
          ],
        ),
      ),
    );
  }

  _VirtualStandViewState(this.stand);
}
