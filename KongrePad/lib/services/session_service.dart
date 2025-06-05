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

  // ✅ MATERIALS METHOD - ŞİMDİ KULLANILIYOR
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
        },
      );

      print('SessionService - Materials API yanıt kodu: ${materialsResponse.statusCode}');
      print('SessionService - Materials API yanıt gövdesi: ${materialsResponse.body}');

      if (materialsResponse.statusCode == 200) {
        final materialsData = jsonDecode(materialsResponse.body);
        if (materialsData['success'] == true && materialsData['data'] != null) {
          final materials = materialsData['data'] as List;
          print('SessionService - ✅ ${materials.length} materyal bulundu');

          if (materials.isNotEmpty) {
            final doc = materials.firstWhere(
                    (material) => material['category'] == 'presentation',
                orElse: () => materials.first
            );

            var downloadUrl = doc['download_url'];
            print('SessionService - Download URL ham: $downloadUrl');

            // URL düzeltme
            if (downloadUrl != null && !downloadUrl.toString().startsWith('http')) {
              if (downloadUrl.toString().startsWith('/')) {
                downloadUrl = 'https://api.kongrepad.com$downloadUrl';
              } else {
                downloadUrl = 'https://api.kongrepad.com/$downloadUrl';
              }
              print('SessionService - URL düzeltildi: $downloadUrl');
            }

            print('SessionService - ✅ PDF BULUNDU: $downloadUrl');

            return {
              'pdf_url': downloadUrl,
              'session_id': session['id'].toString(),
              'title': session['title'],
              'description': session['description'],
              'source': 'materials_api'
            };
          }
        }
      } else if (materialsResponse.statusCode == 500) {
        print('SessionService - Materials API 500 hatası, direkt document deneniyor...');

        // 2. Backend hatası varsa direkt document_id dene
        final documentId = session['document_id'];
        if (documentId != null && documentId != 0) {
          print('SessionService - Document ID bulundu: $documentId');

          final directUrls = [
            'https://api.kongrepad.com/api/v1/documents/$documentId/download',
            'https://api.kongrepad.com/storage/documents/$documentId.pdf',
            'https://api.kongrepad.com/uploads/documents/$documentId.pdf',
            'https://api.kongrepad.com/storage/sessions/$sessionId/document.pdf',
            'https://api.kongrepad.com/storage/meetings/6/documents/$documentId.pdf',
          ];

          for (String testUrl in directUrls) {
            try {
              print('SessionService - Direct URL test: $testUrl');

              final testResponse = await http.get(  // HEAD yerine GET dene
                Uri.parse(testUrl),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Accept': 'application/pdf, application/octet-stream, */*',
                },
              );

              print('SessionService - Direct URL status: ${testResponse.statusCode}');

              if (testResponse.statusCode == 200) {
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
            } catch (e) {
              print('SessionService - Direct URL error: $e');
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
      'description': session['description'] ?? 'Bu oturum için doküman bulunamadı'
    };
  }

  // Test metodu
  Future<void> testMaterialsEndpoint(int sessionId) async {
    print('=== MATERIALS ENDPOINT TEST ===');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('TEST - Token yok');
        return;
      }

      // Materials endpoint'ini test et
      final materialsResponse = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/materials'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      print('Materials Status: ${materialsResponse.statusCode}');
      print('Materials Body: ${materialsResponse.body}');

    } catch (e) {
      print('TEST ERROR: $e');
    }

    print('=== TEST BİTTİ ===');
  }
}