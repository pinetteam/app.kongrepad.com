import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class SurveyService {
  static const String baseUrl = 'https://api.kongrepad.com/api/v1';

  /// Get list of available surveys
  /// API: GET /api/v1/surveys
  Future<Map<String, dynamic>> getSurveys({
    String? status,
    int? meetingId,
    bool? participated,
    int? limit,
    int? page,
  }) async {
    print('SurveyService - getSurveys başladı');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('SurveyService - HATA: Token bulunamadı');
        return {'success': false, 'data': [], 'message': 'Token bulunamadı'};
      }

      // Query parameters oluştur
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (meetingId != null) queryParams['meeting_id'] = meetingId.toString();
      if (participated != null)
        queryParams['participated'] = participated.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (page != null) queryParams['page'] = page.toString();

      final uri = Uri.parse('$baseUrl/surveys').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('SurveyService - Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('SurveyService - Response Status: ${response.statusCode}');
      print('SurveyService - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];

          // API now returns paginated format: {"items": [...], "pagination": {...}}
          List<dynamic> surveysData;
          if (data is Map && data.containsKey('items')) {
            surveysData = data['items'] as List;
          } else if (data is List) {
            surveysData = data;
          } else {
            print('SurveyService - Unexpected data format: $data');
            surveysData = [];
          }

          print('SurveyService - ✅ ${surveysData.length} survey bulundu');

          return {
            'success': true,
            'data': surveysData,
            'pagination': data is Map ? data['pagination'] : null,
            'message': 'Surveys retrieved successfully'
          };
        } else {
          print('SurveyService - API success=false veya data=null');
          return {
            'success': false,
            'data': [],
            'message': jsonData['message'] ?? 'No surveys found'
          };
        }
      } else if (response.statusCode == 401) {
        print('SurveyService - Unauthorized (401)');
        return {
          'success': false,
          'data': [],
          'message': 'Oturum süresi dolmuş'
        };
      } else if (response.statusCode == 403) {
        print('SurveyService - Forbidden (403)');
        return {
          'success': false,
          'data': [],
          'message': 'Bu işlem için yetkiniz yok'
        };
      } else {
        print('SurveyService - HTTP Error: ${response.statusCode}');
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'success': false,
          'data': [],
          'message': errorBody['message'] ??
              'Anketler yüklenemedi (${response.statusCode})'
        };
      }
    } catch (e) {
      print('SurveyService - Exception Error: $e');
      return {'success': false, 'data': [], 'message': 'Bağlantı hatası: $e'};
    }
  }

  /// Get survey details with questions
  /// API: GET /api/v1/surveys/{id}
  Future<Map<String, dynamic>> getSurveyDetails(int surveyId,
      {bool includeResults = false}) async {
    print('SurveyService - getSurveyDetails başladı, surveyId: $surveyId');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('SurveyService - HATA: Token bulunamadı');
        return {'success': false, 'data': null, 'message': 'Token bulunamadı'};
      }

      // Query parameters
      final queryParams = <String, String>{};
      if (includeResults) queryParams['include_results'] = 'true';

      final uri = Uri.parse('$baseUrl/surveys/$surveyId').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('SurveyService - Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print(
          'SurveyService - Survey Details Response Status: ${response.statusCode}');
      print('SurveyService - Survey Details Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final surveyData = jsonData['data'];
          print(
              'SurveyService - ✅ Survey details alındı: ${surveyData['title']}');

          // Questions varsa say
          if (surveyData['questions'] != null) {
            final questionsData = surveyData['questions'];

            // ✅ YENİ: Questions formatını kontrol et
            if (questionsData is List) {
              print('SurveyService - ${questionsData.length} question bulundu');

              // Her question'ın formatını kontrol et
              for (int i = 0; i < questionsData.length; i++) {
                final question = questionsData[i];
                if (question is! Map<String, dynamic>) {
                  print(
                      'SurveyService - Question $i Map değil: ${question.runtimeType}');
                } else if (question['id'] == null) {
                  print('SurveyService - Question $i ID null');
                }
              }
            } else {
              print(
                  'SurveyService - Questions List değil: ${questionsData.runtimeType}');
            }
          }

          return {
            'success': true,
            'data': surveyData,
            'message': 'Survey details retrieved successfully'
          };
        } else {
          print('SurveyService - Survey details success=false');
          return {
            'success': false,
            'data': null,
            'message': jsonData['message'] ?? 'Anket bulunamadı'
          };
        }
      } else if (response.statusCode == 404) {
        print('SurveyService - Survey not found (404)');
        return {'success': false, 'data': null, 'message': 'Anket bulunamadı'};
      } else if (response.statusCode == 401) {
        print('SurveyService - Unauthorized (401)');
        return {
          'success': false,
          'data': null,
          'message': 'Oturum süresi dolmuş'
        };
      } else if (response.statusCode == 403) {
        print('SurveyService - Forbidden (403)');
        return {
          'success': false,
          'data': null,
          'message': 'Bu ankete erişim yetkiniz yok'
        };
      } else {
        print('SurveyService - HTTP Error: ${response.statusCode}');
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'success': false,
          'data': null,
          'message': errorBody['message'] ??
              'Anket detayları yüklenemedi (${response.statusCode})'
        };
      }
    } catch (e) {
      print('SurveyService - Exception Error: $e');
      return {'success': false, 'data': null, 'message': 'Bağlantı hatası: $e'};
    }
  }

  /// Validate survey responses before submission
  static Map<String, dynamic> validateResponses(
      List<Map<String, dynamic>> responses) {
    print('SurveyService - Validating responses: $responses');

    if (responses.isEmpty) {
      return {'valid': false, 'message': 'En az bir soru cevaplanmalıdır'};
    }

    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];

      if (response['question_id'] == null) {
        return {'valid': false, 'message': 'Soru ${i + 1}: question_id eksik'};
      }

      if (response['option_id'] == null) {
        return {'valid': false, 'message': 'Soru ${i + 1}: option_id eksik'};
      }

      // Check if IDs are valid integers
      if (response['question_id'] is! int) {
        return {
          'valid': false,
          'message': 'Soru ${i + 1}: question_id sayı olmalıdır'
        };
      }

      if (response['option_id'] is! int) {
        return {
          'valid': false,
          'message': 'Soru ${i + 1}: option_id sayı olmalıdır'
        };
      }
    }

    print('SurveyService - ✅ Responses validation passed');
    return {'valid': true, 'message': 'Responses are valid'};
  }

  /// Submit survey responses
  /// API: POST /api/v1/surveys/{id}/submit
  Future<Map<String, dynamic>> submitSurvey(
      int surveyId, List<Map<String, dynamic>> responses) async {
    print('SurveyService - submitSurvey başladı, surveyId: $surveyId');
    print('SurveyService - Responses: $responses');

    // ✅ YENİ: Validate responses before submission
    final validation = validateResponses(responses);
    if (!validation['valid']) {
      print('SurveyService - Validation failed: ${validation['message']}');
      return {'success': false, 'message': validation['message']};
    }

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('SurveyService - HATA: Token bulunamadı');
        return {'success': false, 'message': 'Token bulunamadı'};
      }

      final url = '$baseUrl/surveys/$surveyId/submit';
      print('SurveyService - Submit URL: $url');

      final body = jsonEncode({
        'responses': responses,
      });

      print('SurveyService - Submit Body: $body');
      print(
          'SurveyService - Request Headers: Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      print('SurveyService - Submit Response Status: ${response.statusCode}');
      print('SurveyService - Submit Response Headers: ${response.headers}');
      print('SurveyService - Submit Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true || jsonResponse['status'] == true) {
          print('SurveyService - ✅ Survey submitted successfully');
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Anket başarıyla gönderildi'
          };
        } else {
          print('SurveyService - Submit failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Anket gönderilemedi'
          };
        }
      } else if (response.statusCode == 400) {
        print('SurveyService - Bad Request (400)');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Geçersiz anket verisi'
        };
      } else if (response.statusCode == 401) {
        print('SurveyService - Unauthorized (401)');
        return {'success': false, 'message': 'Oturum süresi dolmuş'};
      } else if (response.statusCode == 403) {
        print('SurveyService - Forbidden (403)');
        return {
          'success': false,
          'message': 'Bu ankete cevap verme yetkiniz yok'
        };
      } else if (response.statusCode == 422) {
        print('SurveyService - Validation Error (422)');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Anket cevapları geçersiz'
        };
      } else if (response.statusCode == 409) {
        print('SurveyService - Conflict (409) - Already submitted');
        return {'success': false, 'message': 'Bu anketi zaten cevaplamışsınız'};
      } else {
        print('SurveyService - HTTP Error: ${response.statusCode}');
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};

        // ✅ YENİ: Daha detaylı hata mesajları
        String errorMessage;
        if (response.statusCode == 500) {
          errorMessage =
              'Sunucu hatası (500): ${errorBody['message'] ?? 'An error occurred while processing your request'}';
          if (errorBody['incident_id'] != null) {
            errorMessage += '\n\nHata ID: ${errorBody['incident_id']}';
          }
        } else {
          errorMessage = errorBody['message'] ??
              'Anket gönderilemedi (${response.statusCode})';
        }

        return {
          'success': false,
          'message': errorMessage,
          'status_code': response.statusCode,
          'error_code': errorBody['error_code'],
          'incident_id': errorBody['incident_id'],
        };
      }
    } catch (e) {
      print('SurveyService - Submit Exception: $e');
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  /// Get survey results
  /// API: GET /api/v1/surveys/{id}/results
  Future<Map<String, dynamic>> getSurveyResults(int surveyId) async {
    print('SurveyService - getSurveyResults başladı, surveyId: $surveyId');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('SurveyService - HATA: Token bulunamadı');
        return {'success': false, 'data': null, 'message': 'Token bulunamadı'};
      }

      final url = '$baseUrl/surveys/$surveyId/results';
      print('SurveyService - Results URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('SurveyService - Results Response Status: ${response.statusCode}');
      print('SurveyService - Results Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          print('SurveyService - ✅ Survey results alındı');
          return {
            'success': true,
            'data': jsonData['data'],
            'message': 'Survey results retrieved successfully'
          };
        } else {
          return {
            'success': false,
            'data': null,
            'message': jsonData['message'] ?? 'Sonuçlar bulunamadı'
          };
        }
      } else if (response.statusCode == 403) {
        print('SurveyService - Results access forbidden (403)');
        return {
          'success': false,
          'data': null,
          'message': 'Sonuçları görme yetkiniz yok'
        };
      } else if (response.statusCode == 404) {
        print('SurveyService - Survey not found (404)');
        return {'success': false, 'data': null, 'message': 'Anket bulunamadı'};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'data': null,
          'message': 'Oturum süresi dolmuş'
        };
      } else {
        print('SurveyService - HTTP Error: ${response.statusCode}');
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'success': false,
          'data': null,
          'message': errorBody['message'] ??
              'Sonuçlar yüklenemedi (${response.statusCode})'
        };
      }
    } catch (e) {
      print('SurveyService - Exception Error: $e');
      return {'success': false, 'data': null, 'message': 'Bağlantı hatası: $e'};
    }
  }

  /// Get live voting sessions
  /// API: GET /api/v1/votes/live
  Future<Map<String, dynamic>> getLiveVotes() async {
    print('SurveyService - getLiveVotes başladı');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('SurveyService - HATA: Token bulunamadı');
        return {'success': false, 'data': [], 'message': 'Token bulunamadı'};
      }

      final url = '$baseUrl/votes/live';
      print('SurveyService - Live Votes URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print(
          'SurveyService - Live Votes Response Status: ${response.statusCode}');
      print('SurveyService - Live Votes Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];

          // Handle both paginated and direct list format
          List<dynamic> votesData;
          if (data is Map && data.containsKey('items')) {
            votesData = data['items'] as List;
          } else if (data is List) {
            votesData = data;
          } else {
            print('SurveyService - Unexpected votes data format: $data');
            votesData = [];
          }

          print('SurveyService - ✅ ${votesData.length} live vote bulundu');
          return {
            'success': true,
            'data': votesData,
            'pagination': data is Map ? data['pagination'] : null,
            'message': 'Live votes retrieved successfully'
          };
        } else {
          return {
            'success': false,
            'data': [],
            'message': jsonData['message'] ?? 'Canlı oylama bulunamadı'
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'data': [],
          'message': 'Oturum süresi dolmuş'
        };
      } else {
        print('SurveyService - HTTP Error: ${response.statusCode}');
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'success': false,
          'data': [],
          'message': errorBody['message'] ??
              'Canlı oylamalar yüklenemedi (${response.statusCode})'
        };
      }
    } catch (e) {
      print('SurveyService - Exception Error: $e');
      return {'success': false, 'data': [], 'message': 'Bağlantı hatası: $e'};
    }
  }

  /// Get voting history
  /// API: GET /api/v1/votes/history
  Future<Map<String, dynamic>> getVotingHistory({int? limit, int? page}) async {
    print('SurveyService - getVotingHistory başladı');

    try {
      final token = await AuthService().getStoredToken();
      if (token == null) {
        print('SurveyService - HATA: Token bulunamadı');
        return {'success': false, 'data': [], 'message': 'Token bulunamadı'};
      }

      // Query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (page != null) queryParams['page'] = page.toString();

      final uri = Uri.parse('$baseUrl/votes/history').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('SurveyService - Voting History URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print(
          'SurveyService - Voting History Response Status: ${response.statusCode}');
      print('SurveyService - Voting History Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];

          // Handle both paginated and direct list format
          List<dynamic> historyData;
          if (data is Map && data.containsKey('items')) {
            historyData = data['items'] as List;
          } else if (data is List) {
            historyData = data;
          } else {
            print('SurveyService - Unexpected history data format: $data');
            historyData = [];
          }

          print('SurveyService - ✅ Voting history alındı');
          return {
            'success': true,
            'data': historyData,
            'pagination': data is Map ? data['pagination'] : null,
            'message': 'Voting history retrieved successfully'
          };
        } else {
          return {
            'success': false,
            'data': [],
            'message': jsonData['message'] ?? 'Oylama geçmişi bulunamadı'
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'data': [],
          'message': 'Oturum süresi dolmuş'
        };
      } else {
        print('SurveyService - HTTP Error: ${response.statusCode}');
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'success': false,
          'data': [],
          'message': errorBody['message'] ??
              'Oylama geçmişi yüklenemedi (${response.statusCode})'
        };
      }
    } catch (e) {
      print('SurveyService - Exception Error: $e');
      return {'success': false, 'data': [], 'message': 'Bağlantı hatası: $e'};
    }
  }

  /// Helper method to format choice responses for submit
  static List<Map<String, dynamic>> formatChoiceResponses(
      Map<int, int> selectedAnswers) {
    return selectedAnswers.entries
        .map((entry) => {
              'question_id': entry.key,
              'option_id': entry.value,
            })
        .toList();
  }

  /// Helper method to format text responses for submit
  static List<Map<String, dynamic>> formatTextResponses(
      Map<int, String> textAnswers) {
    return textAnswers.entries
        .map((entry) => {
              'question_id': entry.key,
              'text_value': entry.value,
            })
        .toList();
  }

  /// Helper method to format rating responses for submit
  static List<Map<String, dynamic>> formatRatingResponses(
      Map<int, int> ratingAnswers) {
    return ratingAnswers.entries
        .map((entry) => {
              'question_id': entry.key,
              'rating_value': entry.value,
            })
        .toList();
  }
}
