import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class SessionService {
  static const String baseUrl = 'https://api.kongrepad.com/api/v1';

  Future<Map<String, dynamic>?> getSessionDetails(int hallId) async {
    try {
      final token = await AuthService().getStoredToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/halls/$hallId/session'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('getSessionDetails response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }

      return null;
    } catch (e) {
      print('GetSessionDetails error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getSessionQuestions(int hallId) async {
    print('SessionService - getSessionQuestions başladı, hallId: $hallId');
    try {
      final token = await AuthService().getStoredToken();
      print('SessionService - Token alındı: ${token?.substring(0, 10)}...');

      if (token == null) {
        print('SessionService - HATA: Token bulunamadı');
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/halls/$hallId/questions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('SessionService - Questions API yanıt: ${response.statusCode}');
      print('SessionService - Questions API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('SessionService - Başarılı yanıt: $data');
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }

      print('SessionService - API yanıtı başarısız');
      return null;
    } catch (e, stackTrace) {
      print('SessionService - HATA: $e');
      print('SessionService - Stack trace: $stackTrace');
      return null;
    }
  }

  Future<bool> askQuestion(int hallId, String question) async {
    print(
        'SessionService - askQuestion başladı, hallId: $hallId, soru: $question');
    try {
      final token = await AuthService().getStoredToken();
      print('SessionService - Token alındı: ${token?.substring(0, 10)}...');

      if (token == null) {
        print('SessionService - HATA: Token bulunamadı');
        throw Exception('No token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/halls/$hallId/questions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': question,
        }),
      );

      print('SessionService - Ask Question API yanıt: ${response.statusCode}');
      print(
          'SessionService - Ask Question API response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('SessionService - Başarılı yanıt: $data');
        return data['success'] == true;
      }

      print('SessionService - API yanıtı başarısız');
      return false;
    } catch (e, stackTrace) {
      print('SessionService - HATA: $e');
      print('SessionService - Stack trace: $stackTrace');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSessionStream(int hallId) async {
    print('SessionService - getSessionStream başladı, hallId: $hallId');
    try {
      final token = await AuthService().getStoredToken();
      print('SessionService - Token alındı: ${token?.substring(0, 10)}...');

      if (token == null) {
        print('SessionService - HATA: Token bulunamadı');
        throw Exception('No token found');
      }

      // Sessions endpoint'ini çağır
      final uri = Uri.parse('$baseUrl/halls/$hallId/session');
      print('SessionService - Session API çağrısı yapılıyor: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('SessionService - Session API yanıt kodu: ${response.statusCode}');
      print('SessionService - Session API yanıt gövdesi: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('SessionService - Session yanıtı başarılı: $data');

        if (data['success'] == true && data['data'] != null) {
          final session = data['data'];
          print('SessionService - Session data dönülüyor: $session');
          return {
            'pdf_url': session['document_url'],
            'session_id': session['id'],
            'title': session['title'],
            'description': session['description']
          };
        } else {
          print('SessionService - Session verisi boş');
          return {
            'pdf_url': null,
            'session_id': null,
            'title': 'Aktif oturum bulunamadı',
            'description':
                'Bu salonda şu anda aktif bir oturum bulunmamaktadır.'
          };
        }
      } else if (response.statusCode == 404) {
        print('SessionService - Session bulunamadı (404)');
      } else {
        print(
            'SessionService - Beklenmeyen durum kodu: ${response.statusCode}');
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
