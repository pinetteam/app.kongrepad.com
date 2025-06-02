import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/VirtualStand.dart';
import '../models/meeting.dart';
import '../models/participant.dart';

class AuthService {
  // Get Meeting
  Future<Meeting?> getMeeting() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print('Token bulunamadı');
        return null;
      }

      final url = Uri.parse('https://api.kongrepad.com/api/v1/meetings/current');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('getMeeting status: ${response.statusCode}');
      print('getMeeting response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData.containsKey('data') && jsonData['data'] != null) {
          return Meeting.fromJson(jsonData['data']);
        } else {
          print('Meeting data null geldi');
        }
      } else if (response.statusCode == 401) {
        print('Token geçersiz - tekrar login olunmalı');
        await prefs.remove('token');
      } else {
        print('getMeeting başarısız: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('getMeeting hata: $e');
    }
    return null;
  }

  Future<Participant?> getParticipant() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print('Token bulunamadı');
        return null;
      }

      final url = Uri.parse('https://api.kongrepad.com/api/v1/auth/profile');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('getParticipant status: ${response.statusCode}');
      print('getParticipant response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData.containsKey('data') && jsonData['data'] != null) {
          return Participant.fromJson(jsonData['data']);
        } else {
          print('Participant data null geldi');
        }
      } else if (response.statusCode == 401) {
        print('Token geçersiz - tekrar login olunmalı');
        await prefs.remove('token');
      } else {
        print('getParticipant başarısız: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('getParticipant hata: $e');
    }
    return null;
  }

  // Get Virtual Stands
  Future<List<VirtualStand>> getVirtualStands() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('https://app.kongrepad.com/api/v1/virtual-stand');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData.containsKey('data') && jsonData['data'] is List) {
          return (jsonData['data'] as List)
              .map((stand) => VirtualStand.fromJson(stand))
              .toList();
        }
      }
    } catch (e) {
      print('getVirtualStands hata: $e');
    }
    return [];
  }

  // Save Token
  Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('Token kaydedildi: $token');
  }

  // Get Token
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Token alındı: $token');
    return token;
  }

  // Login metodu - LoginWithCodeView'den çağrılacak
  Future<bool> login(String username, String password) async {
    try {
      final url = Uri.parse('https://api.kongrepad.com/api/v1/auth/login');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('Login status: ${response.statusCode}');
      print('Login response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Token'ı al ve kaydet
        if (jsonData.containsKey('data') && jsonData['data'].containsKey('token')) {
          final token = jsonData['data']['token'];
          await saveToken(token);

          // Meeting ve participant bilgileri varsa kaydet
          if (jsonData['data'].containsKey('meeting')) {
            // Meeting bilgisini local'e kaydet (opsiyonel)
          }
          if (jsonData['data'].containsKey('participant')) {
            // Participant bilgisini local'e kaydet (opsiyonel)
          }

          return true;
        } else {
          print('Login response\'ta token bulunamadı');
        }
      } else {
        print('Login başarısız: ${response.body}');
      }
    } catch (e) {
      print('Login hata: $e');
    }
    return false;
  }

  Future<void> saveParticipantId(int participantId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('participant_id', participantId);
    print('Participant ID kaydedildi: $participantId');
  }

  // Token kontrolü
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Logout
  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('participant_id');
    print('Logout yapıldı');
  }
}