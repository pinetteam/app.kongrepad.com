import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/VirtualStand.dart';
import '../models/meeting.dart';
import '../models/participant.dart';

class AuthService {
  // Get Meeting
  Future<Meeting?> getMeeting() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://app.kongrepad.com/api/v1/meeting');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Meeting.fromJson(jsonData['data']);
    }
    return null;
  }

  // Get Participant
  Future<Participant?> getParticipant() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://app.kongrepad.com/api/v1/participant');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Participant.fromJson(jsonData['data']);
    }
    return null;
  }

  // Get Virtual Stands
  Future<List<VirtualStand>> getVirtualStands() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://app.kongrepad.com/api/v1/virtual-stand');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return (jsonData['data'] as List)
          .map((stand) => VirtualStand.fromJson(stand))
          .toList();
    }
    return [];
  }

  // Save Token
  Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('Token saved: $token');
  }

  // Get Token
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Retrieved Token: $token');
    return token;
  }

  // Example: Login and Save Token
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('http://app.kongrepad.com/api/v1/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final token = jsonData['token'];
      await saveToken(token); // Save token
      return true;
    } else {
      print('Login failed: ${response.body}');
      return false;
    }
  }

  Future<void> saveParticipantId(int participantId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('participant_id', participantId);
    print('Participant ID saved: $participantId');
  }
}
