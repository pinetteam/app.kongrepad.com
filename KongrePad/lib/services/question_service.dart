import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class QuestionService {
  static const String baseUrl = 'https://api.kongrepad.com/api/v1';

  Future<bool> askQuestion(int sessionId, String question,
      {bool anonymous = false, String? category, String? priority}) async {
    print('QuestionService - askQuestion başladı');
    print('QuestionService - Session ID: $sessionId');
    print('QuestionService - Question: $question');
    print('QuestionService - Anonymous: $anonymous');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('QuestionService - HATA: Token bulunamadı');
        throw Exception('No token found');
      }

      // Request body hazırla
      final requestBody = <String, dynamic>{
        'question': question,
        'anonymous': anonymous,
        'session_id': sessionId,
      };

      if (category != null && category.isNotEmpty) {
        requestBody['category'] = category;
      }
      if (priority != null && priority.isNotEmpty) {
        requestBody['priority'] = priority;
      }

      print('QuestionService - Request Body: $requestBody');

      // Olası endpoint'leri sırasıyla dene
      final possibleEndpoints = [
        '$baseUrl/questions',                              // 1. Genel questions endpoint
        '$baseUrl/sessions/$sessionId/submit-question',    // 2. Submit specific endpoint
        '$baseUrl/sessions/$sessionId/question',           // 3. Singular question
        '$baseUrl/questions/submit',                       // 4. Questions submit endpoint
        '$baseUrl/sessions/questions',                     // 5. Sessions questions POST
      ];

      for (String endpoint in possibleEndpoints) {
        print('QuestionService - Trying endpoint: $endpoint');

        try {
          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          );

          print('QuestionService - Endpoint $endpoint Status: ${response.statusCode}');
          print('QuestionService - Response: ${response.body}');

          // 405 Method Not Allowed ise bir sonraki endpoint'i dene
          if (response.statusCode == 405) {
            print('QuestionService - Method not allowed, trying next endpoint...');
            continue;
          }

          // 500 ve method not allowed mesajı varsa devam et
          if (response.statusCode == 500) {
            try {
              final errorData = jsonDecode(response.body);
              if (errorData['message'].toString().contains('POST method is not supported')) {
                print('QuestionService - POST not supported, trying next endpoint...');
                continue;
              }
            } catch (e) {
              // JSON parse edilemezse de devam et
            }
          }

          // Success response kontrolü
          if (response.statusCode >= 200 && response.statusCode < 300) {
            try {
              final data = jsonDecode(response.body);
              print('QuestionService - SUCCESS with endpoint: $endpoint');
              print('QuestionService - Response data: $data');

              final isSuccess = data['success'] == true ||
                  data['status'] == true ||
                  response.statusCode == 201;

              if (isSuccess) {
                print('QuestionService - Soru başarıyla gönderildi');
                return true;
              }
            } catch (jsonError) {
              // JSON parse hatası olsa bile status code doğruysa başarılı say
              if (response.statusCode == 201 || response.statusCode == 200) {
                print('QuestionService - Success based on status code');
                return true;
              }
            }
          }

          // 400-499 range'inde ise daha fazla deneme
          if (response.statusCode >= 400 && response.statusCode < 500) {
            print('QuestionService - Client error ${response.statusCode}, stopping attempts');
            return false;
          }

        } catch (e) {
          print('QuestionService - Endpoint $endpoint error: $e');
          continue; // Bir sonraki endpoint'i dene
        }
      }

      print('QuestionService - Tüm endpoint\'ler denendi, hiçbiri çalışmadı');
      return false;

    } catch (e, stackTrace) {
      print('QuestionService - Ask Question EXCEPTION: $e');
      print('QuestionService - StackTrace: $stackTrace');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getSessionQuestions(int sessionId) async {
    print('QuestionService - getSessionQuestions başladı, sessionId: $sessionId');
    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('QuestionService - HATA: Token bulunamadı');
        throw Exception('No token found');
      }

      // Bu endpoint çalışıyor (GET destekliyor)
      final url = '$baseUrl/sessions/$sessionId/questions';
      print('QuestionService - Get Questions URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('QuestionService - Get Questions API yanıt kodu: ${response.statusCode}');
      print('QuestionService - Get Questions API yanıt gövdesi: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final questions = List<Map<String, dynamic>>.from(data['data']);
          print('QuestionService - ${questions.length} soru bulundu');
          return questions;
        }
      }

      return [];
    } catch (e, stackTrace) {
      print('QuestionService - Get Questions EXCEPTION: $e');
      return [];
    }
  }

  // Manual test için backend endpoint'lerini kontrol et
  Future<void> testAvailableEndpoints(int sessionId) async {
    final token = await AuthService().getStoredToken();
    if (token == null) return;

    final testEndpoints = [
      '$baseUrl/questions',
      '$baseUrl/sessions/$sessionId/questions',
      '$baseUrl/sessions/$sessionId/question',
      '$baseUrl/sessions/$sessionId/submit-question',
      '$baseUrl/questions/submit',
      '$baseUrl/sessions/questions',
    ];

    print('=== ENDPOINT TEST BAŞLADI ===');

    for (String endpoint in testEndpoints) {
      try {
        // OPTIONS request ile desteklenen metodları öğren
        final optionsResponse = await http.get(
          Uri.parse(endpoint.replaceAll('questions', 'test')),
          headers: {'Authorization': 'Bearer $token'},
        );

        // POST request dene
        final postResponse = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'test': 'data'}),
        );

        print('ENDPOINT: $endpoint');
        print('POST Status: ${postResponse.statusCode}');
        print('Response: ${postResponse.body.substring(0, 100)}...');
        print('---');

      } catch (e) {
        print('ENDPOINT: $endpoint - ERROR: $e');
      }
    }

    print('=== ENDPOINT TEST BİTTİ ===');
  }
}