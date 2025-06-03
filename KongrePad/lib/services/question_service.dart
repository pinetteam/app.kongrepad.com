import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class QuestionService {
  static const String baseUrl = 'https://api.kongrepad.com/api/v1';

  Future<bool> askQuestion(int sessionId, String question,
      {bool anonymous = false}) async {
    print('QuestionService - askQuestion başladı');
    print('QuestionService - Session ID: $sessionId');
    print('QuestionService - Question: $question');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('QuestionService - HATA: Token bulunamadı');
        throw Exception('No token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/sessions/$sessionId/questions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': question,
          'anonymous': anonymous,
          'session_id': sessionId
        }),
      );

      print(
          'QuestionService - Ask Question API yanıt kodu: ${response.statusCode}');
      print(
          'QuestionService - Ask Question API yanıt gövdesi: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('QuestionService - Ask Question HATA: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getSessionQuestions(int sessionId) async {
    print(
        'QuestionService - getSessionQuestions başladı, sessionId: $sessionId');
    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('QuestionService - HATA: Token bulunamadı');
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionId/questions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print(
          'QuestionService - Questions API yanıt kodu: ${response.statusCode}');
      print('QuestionService - Questions API yanıt gövdesi: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }

      return null;
    } catch (e) {
      print('QuestionService - Questions HATA: $e');
      return null;
    }
  }
}
