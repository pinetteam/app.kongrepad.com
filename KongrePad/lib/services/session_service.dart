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

  Future<Map<String, dynamic>?> getActiveSession(int hallId) async {
    print('SessionService - getActiveSession başladı, hallId: $hallId');
    try {
      final token = await AuthService().getStoredToken();
      print('SessionService - Token alındı: ${token?.substring(0, 10)}...');

      if (token == null) {
        print('SessionService - HATA: Token bulunamadı');
        throw Exception('No token found');
      }

      // Önce aktif toplantıyı al
      final currentMeetingResponse = await http.get(
        Uri.parse('$baseUrl/meetings/current'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('SessionService - Current Meeting API yanıt kodu: ${currentMeetingResponse.statusCode}');

      if (currentMeetingResponse.statusCode != 200) {
        print('SessionService - Current Meeting API failed');
        return null;
      }

      final meetingData = jsonDecode(currentMeetingResponse.body);
      if (meetingData['success'] != true || meetingData['data'] == null) {
        print('SessionService - Meeting data invalid');
        return null;
      }

      final meetingId = meetingData['data']['id'];
      print('SessionService - Active Meeting ID alındı: $meetingId');

      // Current activities'ten live sessions'ı al
      final currentActivities = meetingData['data']['current_activities'];
      if (currentActivities != null && currentActivities['live_sessions'] != null) {
        final liveSessions = currentActivities['live_sessions'] as List;
        print('SessionService - Current activities den ${liveSessions.length} live session bulundu');

        // Debug: Tüm sessions'ları listele
        for (int i = 0; i < liveSessions.length; i++) {
          final session = liveSessions[i];
          final programHallId = session['program']?['hall_id'];
          print('SessionService - Session $i: ID=${session['id']}, Program Hall ID=$programHallId, Title=${session['title']}');
        }

        print('SessionService - Aranan Hall ID: $hallId');

        // 1. Önce tam eşleşme dene
        var currentSession = liveSessions.firstWhere(
                (session) =>
            session['program'] != null &&
                session['program']['hall_id'] == hallId,
            orElse: () => null
        );

        // 2. Tam eşleşme yoksa alternatif seç
        if (currentSession == null) {
          print('SessionService - Hall ID $hallId için aktif session bulunamadı');

          if (liveSessions.isNotEmpty) {
            currentSession = liveSessions.first;
            final actualHallId = currentSession['program']?['hall_id'];
            print('SessionService - ⚠️ ALTERNATIF SESSION KULLANILIYOR ⚠️');
            print('SessionService - İstenen Hall ID: $hallId');
            print('SessionService - Kullanılan Session: ID=${currentSession['id']}, Hall ID=$actualHallId');
            print('SessionService - Session Title: ${currentSession['title']}');
          } else {
            return {
              'pdf_url': null,
              'session_id': null,
              'title': 'Aktif Oturum Bulunamadı',
              'description': 'Şu anda hiçbir hall\'da aktif oturum yok'
            };
          }
        }

        print('SessionService - Aktif oturum seçildi: ${currentSession['id']}');

        // ✅ ŞİMDİ MATERIALS'I AL
        return await _getMaterials(currentSession, token);
      }

      return {
        'pdf_url': null,
        'session_id': null,
        'title': 'Aktif Oturum Bulunamadı',
        'description': 'Şu anda hiçbir oturum aktif değil'
      };

    } catch (e, stackTrace) {
      print('SessionService - HATA: $e');
      print('SessionService - Stack trace: $stackTrace');
      return null;
    }
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
        print('SessionService - ✅ SUCCESS: Content-Length: $contentLength, Content-Type: $contentType');

        // Content-Length kontrolü
        if (contentLength != null) {
          final size = int.tryParse(contentLength) ?? 0;
          if (size < 1024) { // 1KB'den küçükse şüpheli
            print('SessionService - ⚠️ UYARI: Dosya boyutu çok küçük ($size bytes)');
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

  // ✅ MATERIALS METHOD - GELİŞTİRİLMİŞ VERSİYON
  Future<Map<String, dynamic>> _getMaterials(Map<String, dynamic> session, String token) async {
    final sessionId = session['id'];
    print('SessionService - _getMaterials başladı, sessionId: $sessionId');

    try {
      // 1. Materials API'yi dene
      final materialsResponse = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/materials'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'User-Agent': 'KongrePad Mobile App',
        },
      );

      print('SessionService - Materials API yanıt kodu: ${materialsResponse.statusCode}');
      print('SessionService - Materials API Headers: ${materialsResponse.headers}');
      print('SessionService - Materials API yanıt gövdesi: ${materialsResponse.body}');

      if (materialsResponse.statusCode == 200) {
        final materialsData = jsonDecode(materialsResponse.body);
        print('SessionService - RAW Materials Data: $materialsData');

        if (materialsData['success'] == true && materialsData['data'] != null) {
          final materials = materialsData['data'] as List;
          print('SessionService - ✅ ${materials.length} materyal bulundu');

          if (materials.isNotEmpty) {
            // Her material'ı detaylı logla
            for (int i = 0; i < materials.length; i++) {
              final material = materials[i];
              print('SessionService - Material $i:');
              print('  - ID: ${material['id']}');
              print('  - Category: ${material['category']}');
              print('  - File Name: ${material['file_name']}');
              print('  - Download URL: ${material['download_url']}');
              print('  - File Path: ${material['file_path']}');
              print('  - MIME Type: ${material['mime_type']}');
              print('  - URL: ${material['url']}');
            }

            // Presentation kategorisindeki ilk dokümanı tercih et
            var selectedMaterial = materials.firstWhere(
                    (material) => material['category'] == 'presentation',
                orElse: () => materials.first
            );

            print('SessionService - Seçilen material: ${selectedMaterial['id']} - ${selectedMaterial['category']}');

            // Farklı URL alanlarını dene
            final possibleUrlFields = [
              'download_url',
              'file_path',
              'url',
              'file_url',
              'document_url'
            ];

            String? workingUrl;

            for (String urlField in possibleUrlFields) {
              if (selectedMaterial[urlField] != null) {
                final rawUrl = selectedMaterial[urlField].toString();
                final fixedUrl = _fixDownloadUrl(rawUrl);

                if (fixedUrl != null) {
                  // URL'i test et
                  final isWorking = await _testSingleUrl(fixedUrl, token);
                  if (isWorking) {
                    workingUrl = fixedUrl;
                    print('SessionService - ✅ ÇALIŞAN URL BULUNDU ($urlField): $workingUrl');
                    break;
                  }
                }
              }
            }

            if (workingUrl != null) {
              return {
                'pdf_url': workingUrl,
                'session_id': session['id'].toString(),
                'title': session['title'],
                'description': session['description'],
                'source': 'materials_api',
                'material_id': selectedMaterial['id'].toString(),
                'material_category': selectedMaterial['category'],
                'file_name': selectedMaterial['file_name']
              };
            } else {
              print('SessionService - ⚠️ Materials bulundu ama hiçbir URL çalışmıyor');
            }
          }
        }
      } else if (materialsResponse.statusCode == 500) {
        print('SessionService - Materials API 500 hatası, direkt document deneniyor...');
      } else if (materialsResponse.statusCode == 404) {
        print('SessionService - Materials API 404 - Endpoint bulunamadı');
      } else if (materialsResponse.statusCode == 403) {
        print('SessionService - Materials API 403 - Yetki hatası');
      } else {
        print('SessionService - Materials API beklenmeyen hata: ${materialsResponse.statusCode}');
      }

      // 2. Materials API başarısız olduysa, direkt document_id ile dene
      print('SessionService - Materials API başarısız, alternatif yöntemler deneniyor...');

      final documentId = session['document_id'];
      if (documentId != null && documentId != 0) {
        print('SessionService - Document ID bulundu: $documentId');

        final directUrls = [
          'https://api.kongrepad.com/api/v1/documents/$documentId/download',
          'https://api.kongrepad.com/storage/documents/$documentId.pdf',
          'https://api.kongrepad.com/uploads/documents/$documentId.pdf',
          'https://api.kongrepad.com/storage/sessions/$sessionId/document.pdf',
          'https://api.kongrepad.com/storage/meetings/6/documents/$documentId.pdf',
          'https://api.kongrepad.com/api/v1/sessions/$sessionId/document',
          'https://api.kongrepad.com/files/documents/$documentId',
        ];

        for (String testUrl in directUrls) {
          final isWorking = await _testSingleUrl(testUrl, token);
          if (isWorking) {
            print('SessionService - ✅ DIRECT PDF BULUNDU: $testUrl');

            return {
              'pdf_url': testUrl,
              'session_id': session['id'].toString(),
              'title': session['title'],
              'description': session['description'],
              'source': 'direct_document_url',
              'document_id': documentId.toString()
            };
          }
        }
      }

      // 3. Session içinde başka PDF alanları var mı kontrol et
      final sessionUrlFields = ['pdf_url', 'document_url', 'file_url', 'attachment_url'];
      for (String field in sessionUrlFields) {
        if (session[field] != null) {
          final fixedUrl = _fixDownloadUrl(session[field].toString());
          if (fixedUrl != null) {
            final isWorking = await _testSingleUrl(fixedUrl, token);
            if (isWorking) {
              print('SessionService - ✅ SESSION PDF BULUNDU ($field): $fixedUrl');

              return {
                'pdf_url': fixedUrl,
                'session_id': session['id'].toString(),
                'title': session['title'],
                'description': session['description'],
                'source': 'session_field',
                'field_name': field
              };
            }
          }
        }
      }

    } catch (e) {
      print('SessionService - _getMaterials error: $e');
    }

    // Hiçbir PDF bulunamadı
    print('SessionService - ❌ Hiçbir PDF bulunamadı');
    return {
      'pdf_url': null,
      'session_id': session['id'].toString(),
      'title': session['title'],
      'description': session['description'] ?? 'Bu oturum için doküman bulunamadı',
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
              print('$endpoint - Body (first 100 chars): ${response.body.substring(0, 100)}...');
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
          final icon = status == 200 ? '✅' : status == 404 ? '❌' : status == 403 ? '🔒' : '⚠️';

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
}