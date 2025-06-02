import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../Models/VirtualStand.dart';
import '../models/meeting.dart';
import '../models/participant.dart';

class AuthService {
  static const String baseUrl = 'https://api.kongrepad.com/api/v1';

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'device_name': androidInfo.model,
        'device_id': androidInfo.id,
        'app_version': packageInfo.version,
        'os_version': androidInfo.version.release,
        'os_type': 'android'
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'device_name': iosInfo.name,
        'device_id': iosInfo.identifierForVendor,
        'app_version': packageInfo.version,
        'os_version': iosInfo.systemVersion,
        'os_type': 'ios'
      };
    }
    return {};
  }

  Future<Map<String, dynamic>> login(String username, String? pushToken) async {
    try {
      final deviceInfo = await _getDeviceInfo();

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'push_token': pushToken,
          ...deviceInfo,
          'language': 'tr',
          'timezone': 'Europe/Istanbul'
        }),
      );

      print('Login response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final token = data['data']['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          return data['data'];
        }
      }

      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
      }

      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Failed to get profile');
    } catch (e) {
      print('GetProfile error: $e');
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<Meeting?> getMeeting() async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/meetings/current'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('getMeeting response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Meeting.fromJson(data['data']);
        }
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
      }

      return null;
    } catch (e) {
      print('GetMeeting error: $e');
      return null;
    }
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> logout() async {
    try {
      final token = await getStoredToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _handleUnauthorized();
    }
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
        print(
            'getParticipant başarısız: ${response.statusCode} - ${response.body}');
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
}
