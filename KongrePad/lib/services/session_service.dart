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
      print('SessionService - Current Meeting API yanıt gövdesi: ${currentMeetingResponse.body}');

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

        // Önce tam eşleşme dene
        var currentSession = liveSessions.firstWhere(
                (session) =>
            session['program'] != null &&
                session['program']['hall_id'] == hallId,
            orElse: () => null
        );

        // Eğer tam eşleşme bulunamazsa, boş session bilgisi döndür
        if (currentSession == null) {
          print('SessionService - Hall ID $hallId için aktif session bulunamadı');
          return {
            'pdf_url': null,
            'session_id': null,
            'title': 'Bu Hall\'da Aktif Oturum Yok',
            'description': 'Hall ID $hallId için şu anda aktif bir oturum bulunmuyor'
          };
        }

        if (currentSession != null) {
          print('SessionService - Aktif oturum bulundu: ${currentSession['id']}');
          print('SessionService - Oturum detayları: $currentSession');

          // Session ID ile materials al
          final sessionId = currentSession['id'];
          print('SessionService - Session ID bulundu: $sessionId');

          // Materials endpoint'ini kullan
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
              print('SessionService - Bulunan materyal sayısı: ${materials.length}');

              // Presentation dokümanını bul
              final presentationDoc = materials.firstWhere(
                      (material) => material['category'] == 'presentation',
                  orElse: () => materials.isNotEmpty ? materials.first : null
              );

              if (presentationDoc != null) {
                final downloadUrl = presentationDoc['download_url'];
                print('SessionService - Materials download URL: $downloadUrl');

                return {
                  'pdf_url': downloadUrl,
                  'session_id': currentSession['id'].toString(),
                  'title': currentSession['title'],
                  'description': currentSession['description'],
                  'document_title': presentationDoc['title'],
                  'document_filename': presentationDoc['filename']
                };
              }
            }
          }

          // Document yoksa sadece session bilgilerini döndür
          return {
            'pdf_url': null,
            'session_id': currentSession['id'].toString(),
            'title': currentSession['title'],
            'description': currentSession['description']
          };
        } else {
          print('SessionService - Hall ID $hallId için aktif session bulunamadı');
        }
      }

      // Fallback: Eski yöntemle sessions/live endpoint'ini dene (Backend hatası varsa atla)
      print('SessionService - Fallback: sessions/live endpoint\'i deneniyor');
      try {
        final liveSessionsResponse = await http.get(
          Uri.parse('$baseUrl/sessions/live'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        print('SessionService - Live Sessions API yanıt kodu: ${liveSessionsResponse.statusCode}');

        // Backend hatası varsa (500) skip et
        if (liveSessionsResponse.statusCode == 500) {
          print('SessionService - Backend hatası (500), live sessions atlanıyor');
          return {
            'pdf_url': null,
            'session_id': null,
            'title': 'Oturum Yükleniyor...',
            'description': 'Hall ID: $hallId için session bilgileri alınıyor'
          };
        }

        if (liveSessionsResponse.statusCode == 200) {
          final liveData = jsonDecode(liveSessionsResponse.body);
          print('SessionService - Live Sessions data: $liveData');

          if (liveData['success'] == true && liveData['data'] != null) {
            final sessions = liveData['data'] as List;
            print('SessionService - Bulunan oturum sayısı: ${sessions.length}');

            // Program içindeki hall_id'ye göre oturumu bul
            final currentSession = sessions.firstWhere(
                    (session) =>
                session['program'] != null &&
                    session['program']['hall_id'] == hallId,
                orElse: () => null
            );

            if (currentSession != null) {
              print('SessionService - Aktif oturum bulundu: ${currentSession['id']}');

              // Materials endpoint'ini dene
              final materialsResponse = await http.get(
                Uri.parse('$baseUrl/sessions/${currentSession['id']}/materials'),
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
                  print('SessionService - Bulunan materyal sayısı: ${materials.length}');

                  // Presentation dokümanını bul
                  final presentationDoc = materials.firstWhere(
                          (material) => material['category'] == 'presentation',
                      orElse: () => materials.isNotEmpty ? materials.first : null
                  );

                  if (presentationDoc != null) {
                    final documentUrl = presentationDoc['download_url'];
                    print('SessionService - Doküman URL: $documentUrl');

                    return {
                      'pdf_url': documentUrl,
                      'session_id': currentSession['id'].toString(),
                      'title': currentSession['title'],
                      'description': currentSession['description']
                    };
                  }
                }
              }

              // Materyal bulunamadıysa session bilgilerini döndür
              return {
                'pdf_url': null,
                'session_id': currentSession['id'].toString(),
                'title': currentSession['title'],
                'description': currentSession['description']
              };
            }
          }
        }
      } catch (fallbackError) {
        print('SessionService - Fallback error: $fallbackError');
      }

      print('SessionService - Hiçbir session bulunamadı');
      return {
        'pdf_url': null,
        'session_id': null,
        'title': 'Aktif Oturum Bulunamadı',
        'description': 'Hall ID: $hallId için aktif bir oturum bulunamadı'
      };

    } catch (e, stackTrace) {
      print('SessionService - HATA: $e');
      print('SessionService - Stack trace: $stackTrace');
      return null;
    }
  }
}