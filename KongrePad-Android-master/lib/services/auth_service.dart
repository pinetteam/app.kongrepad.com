import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/VirtualStand.dart';
import '../models/meeting.dart';
import '../models/participant.dart';

class AuthService {
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
}
