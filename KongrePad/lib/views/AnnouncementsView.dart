import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_beams/pusher_beams.dart';

import '../Models/Announcement.dart';
import '../l10n/app_localizations.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  List<String> combinedNotifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print("initState: Başladı");
    loadNotifications();
    getData();
    setupPusherBeams();
  }

  Future<void> loadNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedNotifications = prefs.getStringList('notifications');

    setState(() {
      combinedNotifications = savedNotifications ?? [];
    });

    print("SharedPreferences'tan yüklenen bildirimler: $combinedNotifications");
  }

  void setupPusherBeams() {
    print("setupPusherBeams: Başladı");

    PusherBeams.instance.onMessageReceivedInTheForeground((notification) async {
      print("setupPusherBeams: Bildirim alındı: $notification");

      final title = notification['title']?.toString() ?? 'Yeni Bildirim';
      final body = notification['body']?.toString() ?? 'Bir bildirim aldınız';

      print("setupPusherBeams: Title: $title, Body: $body");

      setState(() {
        combinedNotifications.add("$title: $body");
      });

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedNotifications = prefs.getStringList('notifications') ?? [];
      savedNotifications.add("$title: $body");
      await prefs.setStringList('notifications', savedNotifications);

      print("setupPusherBeams: Bildirim kaydedildi ve listeye eklendi.");
    });
  }

  Future<void> getData() async {
    print('getData: Başladı');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Farklı key'leri deneyelim
    int? meetingId = prefs.getInt('meeting_id');

    // Eğer meeting_id yoksa, diğer olası key'leri deneyelim
    if (meetingId == null) {
      // meeting veya participant verilerinden meeting ID'yi çıkaralım
      String? meetingData = prefs.getString('meeting');
      String? participantData = prefs.getString('participant');

      if (meetingData != null) {
        try {
          final meeting = jsonDecode(meetingData);
          meetingId = meeting['id'];
          print('getData: Meeting data\'dan ID alındı: $meetingId');
        } catch (e) {
          print('getData: Meeting data parse edilemedi: $e');
        }
      }

      if (meetingId == null && participantData != null) {
        try {
          final participant = jsonDecode(participantData);
          meetingId = participant['meeting']?['id'];
          print('getData: Participant data\'dan meeting ID alındı: $meetingId');
        } catch (e) {
          print('getData: Participant data parse edilemedi: $e');
        }
      }
    }

    if (token == null) {
      print('getData: Token bulunamadı');
      setState(() {
        _loading = false;
      });
      return;
    }

    if (meetingId == null) {
      print('getData: Meeting ID bulunamadı');
      setState(() {
        _loading = false;
      });
      return;
    }

    print('getData: Token bulundu: $token, Meeting ID: $meetingId');

    try {
      final url = Uri.parse('https://api.kongrepad.com/api/v1/meetings/$meetingId/announcements');
      print('getData: API isteği gönderiliyor: $url');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print('getData: API isteği tamamlandı, statusCode: ${response.statusCode}');
      print('getData: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('getData: Çözülen JSON: $jsonData');

        // API response yapısını kontrol edelim
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final dataSection = jsonData['data'];

          // Eğer data içinde items varsa, onu kullan
          final announcementsList = dataSection['items'] ?? dataSection;

          if (announcementsList is List) {
            setState(() {
              // API'den gelen duyuruları da combinedNotifications listesine ekle
              for (var announcementData in announcementsList) {
                final title = announcementData['title']?.toString() ?? 'Başlıksız Duyuru';
                combinedNotifications.add(title);
              }
              _loading = false;
            });

            print('getData: Duyurular başarıyla alındı, duyuru sayısı: ${announcementsList.length}');
          } else {
            print('getData: Beklenmeyen veri yapısı - announcements list değil');
            setState(() {
              _loading = false;
            });
          }
        } else {
          print('getData: API yanıtında success=false veya data yok');
          setState(() {
            _loading = false;
          });
        }
      } else {
        print('getData: Yanıt başarısız, statusCode: ${response.statusCode}, body: ${response.body}');
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('getData: Hata: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    return SafeArea(
      child: Scaffold(
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(color: Colors.grey),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  height: screenHeight * 0.1,
                  decoration: const BoxDecoration(color: Colors.redAccent),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: screenHeight * 0.05,
                          width: screenHeight * 0.05,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/icon/chevron.left.svg',
                              color: Colors.redAccent,
                              height: screenHeight * 0.03,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('announcements'),
                            style: const TextStyle(fontSize: 25, color: Colors.white),
                          )
                        ],
                      ),
                    ],
                  ),
                ),

                // Combined bildirimler burada gösteriliyor
                if (combinedNotifications.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...combinedNotifications.map((notification) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icon/bell.svg',
                                    color: Colors.black,
                                    height: screenHeight * 0.03,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      notification,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const Divider(thickness: 2),
                      ],
                    ),
                  )
                else
                // Hiç bildirim yoksa gösterilecek mesaj
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Center(
                      child: Text(
                        'Henüz bildirim yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}