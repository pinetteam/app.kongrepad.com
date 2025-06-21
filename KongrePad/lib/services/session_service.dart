import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class SessionService {
  static const String baseUrl = 'https://api.kongrepad.com/api/v1';

  Future<List<Map<String, dynamic>>?> getHalls(int meetingId) async {
    try {
      final token = await AuthService().getStoredToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/meetings/$meetingId/halls'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Halls API yanıt kodu: ${response.statusCode}');
      print('Halls API yanıt gövdesi: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('GetHalls error: $e');
      return null;
    }
  }
// SessionService'te getActiveSession metodunu BU ŞEKİLDE değiştirin:

  Future<Map<String, dynamic>?> getActiveSession(int hallId) async {
    print('SessionService - getActiveSession başladı, hallId: $hallId');
    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        throw Exception('No token found');
      }

      // Current meeting data'sını al
      final currentActivitiesResponse = await http.get(
        Uri.parse('$baseUrl/meetings/current'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print(
          'SessionService - Current Activities API yanıt kodu: ${currentActivitiesResponse.statusCode}');

      if (currentActivitiesResponse.statusCode == 200) {
        final meetingData = jsonDecode(currentActivitiesResponse.body);

        // ✅ 1. YÖNTEM: Live sessions'dan direkt al
        final currentActivities = meetingData['data']?['current_activities'];
        if (currentActivities != null &&
            currentActivities['live_sessions'] != null) {
          final liveSessions = currentActivities['live_sessions'] as List;

          print('SessionService - ${liveSessions.length} live session bulundu');

          for (var session in liveSessions) {
            final sessionHallId = session['program']?['hall_id'];
            final sessionId = session['id'];
            final documentId = session['document_id']; // ✅ BURADA VAR!

            print(
                'SessionService - Session: ID=$sessionId, Hall=$sessionHallId, DocID=$documentId');

            if (sessionHallId == hallId && documentId != null) {
              print(
                  'SessionService - ✅ BULDUM! Session ID=$sessionId, Document ID=$documentId');

              // PDF URL'ini oluştur
              final pdfUrl =
                  'https://api.kongrepad.com/api/v1/documents/$documentId/download';

              print('SessionService - PDF URL: $pdfUrl');

              return {
                'pdf_url': pdfUrl,
                'session_id': sessionId.toString(),
                'title': session['title'] ?? 'Oturum',
                'description': session['description'] ?? 'Oturum dokümanı',
                'source': 'live_sessions_direct',
                'document_id': documentId.toString(),
                'file_name': session['title'] ?? 'Doküman',
                'real_session_id': sessionId,
                'mapped_hall_id': hallId
              };
            }
          }
        }

        // ✅ 2. YÖNTEM: Halls/programs/sessions'dan al (fallback)
        print(
            'SessionService - Live sessions\'da bulunamadı, halls array\'inde arıyorum...');

        final halls = meetingData['data']?['halls'] as List?;
        if (halls != null) {
          for (var hall in halls) {
            if (hall['id'] == hallId) {
              print('SessionService - Hall bulundu: ${hall['title']}');

              final programs = hall['programs'] as List?;
              if (programs != null && programs.isNotEmpty) {
                final program = programs.first;
                final sessions = program['sessions'] as List?;

                if (sessions != null && sessions.isNotEmpty) {
                  final session = sessions.first;
                  final sessionId = session['id'];
                  final documentId = session['document_id']; // ✅ BURADA DA VAR!

                  print(
                      'SessionService - ✅ HALLS\'DAN BULDUM! Session ID=$sessionId, Document ID=$documentId');

                  if (documentId != null) {
                    final pdfUrl =
                        'https://api.kongrepad.com/api/v1/documents/$documentId/download';

                    return {
                      'pdf_url': pdfUrl,
                      'session_id': sessionId.toString(),
                      'title': session['title'] ?? 'Oturum',
                      'description':
                          session['description'] ?? 'Oturum dokümanı',
                      'source': 'halls_programs_sessions',
                      'document_id': documentId.toString(),
                      'file_name': session['title'] ?? 'Doküman',
                      'real_session_id': sessionId,
                      'mapped_hall_id': hallId
                    };
                  }
                }
              }
            }
          }
        }
      }

      // Hiçbir yerde bulunamadı
      return {
        'pdf_url': null,
        'session_id': null,
        'title': 'Doküman Bulunamadı',
        'description': 'Bu salon için aktif oturum dokümanı bulunamadı',
        'source': 'not_found',
        'mapped_hall_id': hallId
      };
    } catch (e, stackTrace) {
      print('SessionService - HATA: $e');
      print('SessionService - Stack trace: $stackTrace');
      return null;
    }
  }

// SessionService'e bu metodu ekleyin:

  Future<void> debugDocumentId() async {
    print('=== DOCUMENT ID DEBUG ===');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('Token yok');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/meetings/current'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Live sessions'ı kontrol et
        print('\n1. LIVE SESSIONS KONTROLÜ:');
        final liveSessions =
            data['data']?['current_activities']?['live_sessions'];
        if (liveSessions != null) {
          for (var session in liveSessions) {
            print('Session ID: ${session['id']}');
            print('Hall ID: ${session['program']?['hall_id']}');
            print('Document ID: ${session['document_id']}'); // ✅ BURADA OLMALI
            print('Title: ${session['title']}');
            print('---');
          }
        }

        // Halls array'ini kontrol et
        print('\n2. HALLS ARRAY KONTROLÜ:');
        final halls = data['data']?['halls'];
        if (halls != null) {
          for (var hall in halls) {
            print('Hall ID: ${hall['id']} - ${hall['title']}');

            final programs = hall['programs'];
            if (programs != null) {
              for (var program in programs) {
                print('  Program ID: ${program['id']} - ${program['title']}');

                final sessions = program['sessions'];
                if (sessions != null) {
                  for (var session in sessions) {
                    print('    Session ID: ${session['id']}');
                    print(
                        '    Document ID: ${session['document_id']}'); // ✅ BURADA DA OLMALI
                    print('    Title: ${session['title']}');
                  }
                }
              }
            }
            print('---');
          }
        }

        // Document ID ile PDF URL test et
        print('\n3. PDF URL TEST:');
        final documentId = 6; // JSON'da gördüğümüz ID
        final pdfUrl =
            'https://api.kongrepad.com/api/v1/documents/$documentId/download';

        print('Test URL: $pdfUrl');

        final testResponse = await http.head(
          Uri.parse(pdfUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/pdf, application/octet-stream, */*',
          },
        );

        print('Test Sonucu: ${testResponse.statusCode}');
        if (testResponse.statusCode == 200) {
          print('✅ PDF erişilebilir!');
        } else {
          print('❌ PDF erişilemiyor: ${testResponse.statusCode}');
        }
      } else {
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG ERROR: $e');
    }

    print('=== DEBUG BİTTİ ===');
  }

  // ✅ URL Düzeltme Helper Method
  String? _fixDownloadUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;

    print('SessionService - Raw URL: $rawUrl');

    // Zaten tam URL ise olduğu gibi döndür
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }

    // / ile başlıyorsa base URL ekle
    if (rawUrl.startsWith('/')) {
      final fixedUrl = 'https://api.kongrepad.com$rawUrl';
      print('SessionService - URL düzeltildi (slash): $fixedUrl');
      return fixedUrl;
    }

    // Hiçbiriyle başlamıyorsa base URL + / ekle
    final fixedUrl = 'https://api.kongrepad.com/$rawUrl';
    print('SessionService - URL düzeltildi (no slash): $fixedUrl');
    return fixedUrl;
  }

  // ✅ Single URL Test Helper
  Future<bool> _testSingleUrl(String url, String token) async {
    try {
      print('SessionService - Testing URL: $url');

      final response = await http.head(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf, application/octet-stream, */*',
          'User-Agent': 'KongrePad Mobile App',
        },
      );

      print('SessionService - URL Test Result: $url -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentLength = response.headers['content-length'];
        final contentType = response.headers['content-type'];
        print(
            'SessionService - ✅ SUCCESS: Content-Length: $contentLength, Content-Type: $contentType');

        // Content-Length kontrolü
        if (contentLength != null) {
          final size = int.tryParse(contentLength) ?? 0;
          if (size < 1024) {
            // 1KB'den küçükse şüpheli
            print(
                'SessionService - ⚠️ UYARI: Dosya boyutu çok küçük ($size bytes)');
            return false;
          }
        }

        return true;
      }

      return false;
    } catch (e) {
      print('SessionService - ❌ URL Test Error for $url: $e');
      return false;
    }
  }

// ✅ MATERIALS METHOD - DÜZELTİLMİŞ VE TEMİZLENMİŞ VERSİYON
  Future<Map<String, dynamic>> _getMaterials(
      Map<String, dynamic> session, String token) async {
    final sessionId = session['id'];
    print('SessionService - _getMaterials başladı, sessionId: $sessionId');

    try {
      // Materials API'yi çağır
      final materialsResponse = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/materials'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print(
          'SessionService - Materials API yanıt kodu: ${materialsResponse.statusCode}');

      if (materialsResponse.statusCode == 200) {
        final materialsData = jsonDecode(materialsResponse.body);
        print('SessionService - Materials Data: $materialsData');

        if (materialsData['success'] == true &&
            materialsData['data'] != null &&
            materialsData['data']['materials'] != null) {
          // ✅ DÜZELTME: Doğru path ile materials array'ini al
          final materials = materialsData['data']['materials'] as List;
          print('SessionService - ✅ ${materials.length} materyal bulundu');

          if (materials.isNotEmpty) {
            // İlk PDF dokümanını seç
            final material = materials.first;

            print('SessionService - Seçilen material:');
            print('  - ID: ${material['id']}');
            print('  - File Name: ${material['file_name']}');
            print('  - Extension: ${material['file_extension']}');
            print('  - Size: ${material['file_size']} bytes');
            print('  - Download URL: ${material['download_url']}');

            // Farklı URL formatlarını dene - API'den gelen URL'ler öncelikli
            final fileName = material['file_name'];
            final extension = material['file_extension'];
            final materialId = material['id'];

            final possibleUrls = [
              // ✅ API'den gelen URL'ler (şimdilik öncelikli)
              material['download_url'],
              material['file_url'],
              // ✅ YENİ: Meeting ve session bilgisi olan doğru URL
              'https://api.kongrepad.com/api/v1/meetings/6/sessions/$sessionId/materials/$materialId/download',
              // ✅ Backend'in eklediği Documents Controller endpoint'i (henüz 404)
              'https://api.kongrepad.com/api/v1/documents/$materialId/download',
              // ✅ Session bazlı endpoint (henüz 404)
              'https://api.kongrepad.com/api/v1/sessions/$sessionId/materials/$materialId/download',
              // Storage URL'leri (fallback - nginx sorunu var)
              'https://api.kongrepad.com/storage/documents/$fileName.$extension',
              'https://api.kongrepad.com/uploads/documents/$fileName.$extension',
            ];

            String? workingUrl;

            // Her URL'i test et
            for (String? testUrl in possibleUrls) {
              if (testUrl != null && testUrl.isNotEmpty) {
                print('SessionService - Test ediliyor: $testUrl');

                try {
                  final testResponse = await http.head(
                    Uri.parse(testUrl),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Accept': 'application/pdf, application/octet-stream',
                    },
                  );

                  print(
                      'SessionService - Test sonucu: ${testResponse.statusCode}');

                  if (testResponse.statusCode == 200) {
                    workingUrl = testUrl;
                    print(
                        'SessionService - ✅ ÇALIŞAN URL BULUNDU: $workingUrl');
                    break;
                  }
                } catch (e) {
                  print('SessionService - URL test hatası: $e');
                }
              }
            }

            // Çalışan URL bulundu mu?
            if (workingUrl != null) {
              return {
                'pdf_url': workingUrl,
                'session_id': session['id'].toString(),
                'title': session['title'],
                'description': session['description'],
                'source': 'materials_api',
                'material_id': material['id'].toString(),
                'file_name': material['title'] ?? 'Doküman'
              };
            } else {
              // Hiçbir URL çalışmıyor, ama materyal var
              print(
                  'SessionService - ⚠️ Materyal bulundu ama hiçbir URL erişilebilir değil');
              return {
                'pdf_url': null,
                'session_id': session['id'].toString(),
                'title': session['title'],
                'description': 'PDF bulundu ama indirme izni yok (403 hatası)',
                'source': 'materials_found_but_inaccessible',
                'material_id': material['id'].toString(),
                'file_name': material['title'] ?? 'Doküman',
                'debug_urls': possibleUrls.where((url) => url != null).toList()
              };
            }
          }
        }
      } else {
        print(
            'SessionService - Materials API hatası: ${materialsResponse.statusCode}');
      }
    } catch (e) {
      print('SessionService - _getMaterials error: $e');
    }

    // PDF bulunamadı
    print('SessionService - ❌ PDF bulunamadı');
    return {
      'pdf_url': null,
      'session_id': session['id'].toString(),
      'title': session['title'],
      'description': 'Bu oturum için doküman bulunamadı',
      'source': 'no_pdf_found'
    };
  }

  // ✅ DETAYLI MATERIALS ENDPOINT TEST METODU
  Future<void> testMaterialsEndpoint(int sessionId) async {
    print('=== MATERIALS ENDPOINT DEEP TEST ===');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('TEST - Token yok');
        return;
      }

      // 1. Session detayını al
      print('\n1. Session detayı test ediliyor...');
      final sessionResponse = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      print('Session Detail Status: ${sessionResponse.statusCode}');
      print('Session Detail Body: ${sessionResponse.body}');

      // 2. Materials endpoint'ini test et
      print('\n2. Materials endpoint test ediliyor...');
      final materialsResponse = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/materials'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      print('Materials Status: ${materialsResponse.statusCode}');
      print('Materials Headers: ${materialsResponse.headers}');
      print('Materials Body: ${materialsResponse.body}');

      if (materialsResponse.statusCode == 200) {
        final data = jsonDecode(materialsResponse.body);
        if (data['data'] != null) {
          final materials = data['data'] as List;

          print('\n3. Her material için URL test:');
          for (var material in materials) {
            print('--- Material ---');
            print('ID: ${material['id']}');
            print('Category: ${material['category']}');
            print('File Name: ${material['file_name']}');
            print('MIME Type: ${material['mime_type']}');

            // Farklı URL formatlarını test et
            final possibleUrls = [
              material['download_url'],
              material['file_path'],
              material['url'],
              _fixDownloadUrl(material['download_url']?.toString()),
              _fixDownloadUrl(material['file_path']?.toString()),
            ];

            for (var url in possibleUrls) {
              if (url != null && url.toString().isNotEmpty) {
                await _testSingleUrl(url.toString(), token);
              }
            }
            print(''); // Boş satır
          }
        }
      }

      // 3. Document endpoint'lerini test et
      print('\n4. Document endpoint\'leri test ediliyor...');
      final documentEndpoints = [
        '$baseUrl/documents',
        '$baseUrl/sessions/$sessionId/documents',
        '$baseUrl/sessions/$sessionId/files',
        '$baseUrl/sessions/$sessionId/attachments',
      ];

      for (String endpoint in documentEndpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );
          print('$endpoint - Status: ${response.statusCode}');
          if (response.statusCode == 200) {
            if (response.body.length > 100) {
              print(
                  '$endpoint - Body (first 100 chars): ${response.body.substring(0, 100)}...');
            } else {
              print('$endpoint - Body: ${response.body}');
            }
          }
        } catch (e) {
          print('$endpoint - Error: $e');
        }
      }
    } catch (e) {
      print('TEST ERROR: $e');
    }

    print('=== TEST BİTTİ ===');
  }

  // ✅ BACKEND API ENDPOİNT'LERİNİ KEŞFETME METODU
  Future<void> discoverApiEndpoints(int sessionId) async {
    print('=== API ENDPOINT DISCOVERY ===');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) return;

      final endpointsToTest = [
        '$baseUrl/sessions/$sessionId',
        '$baseUrl/sessions/$sessionId/materials',
        '$baseUrl/sessions/$sessionId/documents',
        '$baseUrl/sessions/$sessionId/files',
        '$baseUrl/sessions/$sessionId/attachments',
        '$baseUrl/sessions/$sessionId/resources',
        '$baseUrl/sessions/$sessionId/media',
        '$baseUrl/sessions/$sessionId/presentations',
        '$baseUrl/materials',
        '$baseUrl/documents',
        '$baseUrl/files',
      ];

      for (String endpoint in endpointsToTest) {
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          final status = response.statusCode;
          final icon = status == 200
              ? '✅'
              : status == 404
                  ? '❌'
                  : status == 403
                      ? '🔒'
                      : '⚠️';

          print('$icon $endpoint -> $status');

          if (status == 200 && response.body.length < 500) {
            print('   Response: ${response.body}');
          }
        } catch (e) {
          print('❌ $endpoint -> ERROR: $e');
        }
      }
    } catch (e) {
      print('Discovery error: $e');
    }

    print('=== DISCOVERY BİTTİ ===');
  }

  // ✅ TOKEN İLE PDF ENDPOINT TEST METODU
  Future<void> testPdfEndpointWithToken() async {
    print('=== PDF ENDPOINT TOKEN TEST ===');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('TEST - Token yok');
        return;
      }

      print('TEST - Token alındı: ${token.substring(0, 10)}...');

      // Test edilecek endpoint'ler
      final testEndpoints = [
        'https://api.kongrepad.com/api/v1/documents/1/download',
        'https://api.kongrepad.com/api/v1/sessions/4/materials/1/download',
        // ✅ YENİ: Meeting ve session bilgisi olan doğru URL
        'https://api.kongrepad.com/api/v1/meetings/6/sessions/4/materials/1/download',
        'https://api.kongrepad.com/storage/documents/5d663271-0e85-4522-84d7-ccbc8b835240.pdf',
      ];

      for (String endpoint in testEndpoints) {
        print('\nTEST - Endpoint: $endpoint');

        try {
          final response = await http.head(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf, application/octet-stream, */*',
              'User-Agent': 'KongrePad Mobile App',
            },
          );

          print('TEST - Status: ${response.statusCode}');
          print('TEST - Headers: ${response.headers}');

          if (response.statusCode == 200) {
            final contentLength = response.headers['content-length'];
            final contentType = response.headers['content-type'];
            print(
                'TEST - ✅ SUCCESS: Content-Length: $contentLength, Content-Type: $contentType');
          } else if (response.statusCode == 403) {
            print('TEST - ❌ FORBIDDEN: Token ile erişim izni yok');
          } else if (response.statusCode == 404) {
            print('TEST - ❌ NOT FOUND: Endpoint bulunamadı');
          } else {
            print('TEST - ⚠️ UNEXPECTED: ${response.statusCode}');
          }
        } catch (e) {
          print('TEST - ❌ ERROR: $e');
        }
      }
    } catch (e) {
      print('TEST ERROR: $e');
    }

    print('=== TOKEN TEST BİTTİ ===');
  }
}
