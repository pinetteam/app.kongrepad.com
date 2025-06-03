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

      print(
          'SessionService - Current Meeting API yanıt kodu: ${currentMeetingResponse.statusCode}');
      print(
          'SessionService - Current Meeting API yanıt gövdesi: ${currentMeetingResponse.body}');

      if (currentMeetingResponse.statusCode == 200) {
        final meetingData = jsonDecode(currentMeetingResponse.body);
        if (meetingData['success'] == true && meetingData['data'] != null) {
          final meetingId = meetingData['data']['id'];
          print('SessionService - Active Meeting ID alındı: $meetingId');

          // Aktif oturumları al
          final liveSessionsResponse = await http.get(
            Uri.parse('$baseUrl/sessions/live'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          print(
              'SessionService - Live Sessions API yanıt kodu: ${liveSessionsResponse.statusCode}');
          print(
              'SessionService - Live Sessions API yanıt gövdesi: ${liveSessionsResponse.body}');

          if (liveSessionsResponse.statusCode == 200) {
            final liveData = jsonDecode(liveSessionsResponse.body);
            print('SessionService - Live Sessions data: $liveData');

            if (liveData['success'] == true && liveData['data'] != null) {
              final sessions = liveData['data'] as List;
              print(
                  'SessionService - Bulunan oturum sayısı: ${sessions.length}');

              // Program içindeki hall_id'ye göre oturumu bul
              final currentSession = sessions.firstWhere(
                  (session) =>
                      session['program'] != null &&
                      session['program']['hall_id'] == hallId,
                  orElse: () => null);

              if (currentSession != null) {
                print(
                    'SessionService - Aktif oturum bulundu: ${currentSession['id']}');
                print('SessionService - Oturum detayları: $currentSession');

                // Oturum materyallerini al
                final materialsUrl =
                    '$baseUrl/sessions/${currentSession['id']}/materials';
                print('SessionService - Materials API URL: $materialsUrl');

                final materialsResponse = await http.get(
                  Uri.parse(materialsUrl),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Accept': 'application/json',
                  },
                );

                print(
                    'SessionService - Materials API yanıt kodu: ${materialsResponse.statusCode}');
                print(
                    'SessionService - Materials API yanıt gövdesi: ${materialsResponse.body}');

                if (materialsResponse.statusCode == 200) {
                  final materialsData = jsonDecode(materialsResponse.body);
                  print('SessionService - Materials data: $materialsData');

                  if (materialsData['success'] == true &&
                      materialsData['data'] != null) {
                    final materials = materialsData['data'] as List;
                    print(
                        'SessionService - Bulunan materyal sayısı: ${materials.length}');

                    // Önce presentation kategorisindeki dokümanı ara
                    final presentationDoc = materials.firstWhere(
                        (material) => material['category'] == 'presentation',
                        orElse: () => null);

                    // Eğer presentation yoksa herhangi bir dokümanı al
                    final document = presentationDoc ??
                        (materials.isNotEmpty ? materials.first : null);

                    if (document != null) {
                      final documentUrl = document['download_url'];
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

                // Materyal bulunamadıysa oturum bilgilerini döndür
                return {
                  'pdf_url': null,
                  'session_id': currentSession['id'].toString(),
                  'title': currentSession['title'],
                  'description': currentSession['description']
                };
              }
            }
          }
        }
      }

      print('SessionService - İşlem başarısız');
      return null;
    } catch (e, stackTrace) {
      print('SessionService - HATA: $e');
      print('SessionService - Stack trace: $stackTrace');
      return null;
    }
  }
}
