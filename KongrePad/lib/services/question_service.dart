import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class QuestionService {
  static const String baseUrl = 'https://api.kongrepad.com/api/v1';

  /// Ask a Question - POST /api/v1/sessions/{session_id}/questions
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

      // DOĞRU ENDPOINT: POST /api/v1/sessions/{session_id}/questions
      final url = '$baseUrl/sessions/$sessionId/questions';
      print('QuestionService - URL: $url');

      // Request body hazırla
      final requestBody = <String, dynamic>{
        'question_text': question,
        'anonymous': anonymous,
      };

      // İsteğe bağlı parametreler
      if (category != null && category.isNotEmpty) {
        requestBody['category'] = category;
      }
      if (priority != null && priority.isNotEmpty) {
        requestBody['priority'] = priority;
      }

      print('QuestionService - Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('QuestionService - Status Code: ${response.statusCode}');
      print('QuestionService - Response Body: ${response.body}');

      // Success response kontrolü
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          print('QuestionService - Parsed Response: $data');

          // API response format kontrolü
          final isSuccess = data['success'] == true ||
              data['status'] == true ||
              response.statusCode == 201;

          if (isSuccess) {
            print('QuestionService - ✅ Soru başarıyla gönderildi');
            return true;
          } else {
            print('QuestionService - ❌ API success=false döndü');
            return false;
          }
        } catch (jsonError) {
          print('QuestionService - JSON parse hatası: $jsonError');
          // JSON parse edilemezse ama status code başarılıysa OK say
          if (response.statusCode == 201 || response.statusCode == 200) {
            print(
                'QuestionService - ✅ Status code başarılı, JSON parse hatası göz ardı edildi');
            return true;
          }
          return false;
        }
      } else {
        print('QuestionService - ❌ HTTP Error: ${response.statusCode}');
        print('QuestionService - Error Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('QuestionService - ❌ EXCEPTION: $e');
      print('QuestionService - StackTrace: $stackTrace');
      return false;
    }
  }

  /// List Session Questions - GET /api/v1/sessions/{session_id}/questions
  Future<List<Map<String, dynamic>>?> getSessionQuestions(int sessionId) async {
    print(
        'QuestionService - getSessionQuestions başladı, sessionId: $sessionId');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('QuestionService - HATA: Token bulunamadı');
        throw Exception('No token found');
      }

      // DOĞRU ENDPOINT: GET /api/v1/sessions/{session_id}/questions
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

      print('QuestionService - Get Questions Status: ${response.statusCode}');
      print('QuestionService - Get Questions Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final questions = List<Map<String, dynamic>>.from(data['data']);
          print('QuestionService - ✅ ${questions.length} soru bulundu');
          return questions;
        } else {
          print('QuestionService - ❌ API success=false veya data=null');
          return [];
        }
      } else {
        print('QuestionService - ❌ HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('QuestionService - ❌ Get Questions EXCEPTION: $e');
      print('QuestionService - StackTrace: $stackTrace');
      return [];
    }
  }

  /// Get Question Details - GET /api/v1/questions/{id}
  Future<Map<String, dynamic>?> getQuestionDetails(int questionId) async {
    print(
        'QuestionService - getQuestionDetails başladı, questionId: $questionId');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final url = '$baseUrl/questions/$questionId';
      print('QuestionService - Get Question Details URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print(
          'QuestionService - Question Details Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }

      return null;
    } catch (e) {
      print('QuestionService - ❌ Get Question Details EXCEPTION: $e');
      return null;
    }
  }

  /// Like/Unlike Question - POST /api/v1/questions/{id}/like
  Future<bool> likeQuestion(int questionId) async {
    print('QuestionService - likeQuestion başladı, questionId: $questionId');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final url = '$baseUrl/questions/$questionId/like';
      print('QuestionService - Like Question URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('QuestionService - Like Question Status: ${response.statusCode}');
      print('QuestionService - Like Question Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('QuestionService - ❌ Like Question EXCEPTION: $e');
      return false;
    }
  }

  /// Delete Question - DELETE /api/v1/questions/{id}
  Future<bool> deleteQuestion(int questionId) async {
    print('QuestionService - deleteQuestion başladı, questionId: $questionId');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final url = '$baseUrl/questions/$questionId';
      print('QuestionService - Delete Question URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('QuestionService - Delete Question Status: ${response.statusCode}');
      print('QuestionService - Delete Question Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      return false;
    } catch (e) {
      print('QuestionService - ❌ Delete Question EXCEPTION: $e');
      return false;
    }
  }

  /// Get My Questions - GET /api/v1/questions/my-questions
  Future<List<Map<String, dynamic>>?> getMyQuestions() async {
    print('QuestionService - getMyQuestions başladı');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final url = '$baseUrl/questions/my-questions';
      print('QuestionService - Get My Questions URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('QuestionService - My Questions Status: ${response.statusCode}');
      print('QuestionService - My Questions Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final questions = List<Map<String, dynamic>>.from(data['data']);
          print(
              'QuestionService - ✅ ${questions.length} kendi sorunuz bulundu');
          return questions;
        }
      }

      return [];
    } catch (e) {
      print('QuestionService - ❌ Get My Questions EXCEPTION: $e');
      return [];
    }
  }

  /// Debug: Test current endpoints with verbose logging
  Future<void> debugCurrentEndpoints(int sessionId) async {
    print('=== DEBUG CURRENT ENDPOINTS ===');
    print('Session ID: $sessionId');
    print('Expected table: meeting_hall_program_session_questions');

    final token = await AuthService().getStoredToken();
    if (token == null) return;

    // Test GET endpoint
    try {
      final getUrl = '$baseUrl/sessions/$sessionId/questions';
      print('\n🔍 Testing GET: $getUrl');

      final response = await http.get(
        Uri.parse(getUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 500 &&
          response.body.contains('session_questions')) {
        print('❌ Backend hala yanlış tablo ismi kullanıyor: session_questions');
        print('✅ Doğru tablo ismi: meeting_hall_program_session_questions');
      }
    } catch (e) {
      print('❌ GET test error: $e');
    }

    // Test POST endpoint
    try {
      final postUrl = '$baseUrl/sessions/$sessionId/questions';
      print('\n🔍 Testing POST: $postUrl');

      final response = await http.post(
        Uri.parse(postUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': 'Test question from Flutter app',
          'anonymous': false,
        }),
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 500 &&
          response.body.contains('session_questions')) {
        print('❌ Backend POST da yanlış tablo ismi kullanıyor');
      }
    } catch (e) {
      print('❌ POST test error: $e');
    }
  }
}
