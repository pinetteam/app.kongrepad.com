import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_beams/pusher_beams.dart';

import '../Models/Announcement.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  List<String> combinedNotifications = []; // Hem Pusher Beams hem de API'den gelen bildirimler için liste
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print("initState: Başladı");
    loadNotifications(); // Bildirimleri SharedPreferences'tan yükler
    getData(); // API'den duyuruları alır
    setupPusherBeams(); // Pusher Beams bildirimlerini alır
  }

  // Bildirimleri `SharedPreferences`'tan yükler
  Future<void> loadNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedNotifications = prefs.getStringList('notifications');

    setState(() {
      combinedNotifications = savedNotifications ?? [];
    });

    print("SharedPreferences'tan yüklenen bildirimler: $combinedNotifications");
  }

  // Pusher Beams'ten gelen bildirimleri yakalamak ve ekranda göstermek için setup
  void setupPusherBeams() {
    print("setupPusherBeams: Başladı");

    PusherBeams.instance.onMessageReceivedInTheForeground((notification) async {
      print("setupPusherBeams: Bildirim alındı: $notification");  // Bildirimin içeriğini logla

      final title = notification['title']?.toString() ?? 'Yeni Bildirim';
      final body = notification['body']?.toString() ?? 'Bir bildirim aldınız';

      print("setupPusherBeams: Title: $title, Body: $body");  // Title ve body loglanıyor

      // Gelen bildirimi listeye ekle ve UI'ı güncelle
      setState(() {
        combinedNotifications.add("$title: $body");
      });

      // Bildirimi SharedPreferences'a kaydet
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

    if (token == null) {
      print('getData: Token bulunamadı');
      return;
    }

    print('getData: Token bulundu: $token');

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/announcement');
      print('getData: API isteği gönderiliyor...');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print('getData: API isteği tamamlandı, statusCode: ${response.statusCode}');
      print(response.body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('getData: Çözülen JSON: $jsonData');

        final announcementsJson = AnnouncementsJSON.fromJson(jsonData);

        setState(() {
          // API'den gelen duyuruları da combinedNotifications listesine ekle
          announcementsJson.data?.forEach((announcement) {
            combinedNotifications.add(announcement.title.toString());
          });

          _loading = false;
        });

        print('getData: Duyurular başarıyla alındı, duyuru sayısı: ${announcementsJson.data?.length}');
      } else {
        print('getData: Yanıt başarısız, statusCode: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      print('getData: Hata: $e');
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
              ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey),
              child: Column(children: [
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white, // Circular background color
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Bildirimler",
                            style: TextStyle(fontSize: 25, color: Colors.white),
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
                                color: Colors.white, // Bildirim için ayrı bir alan
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
                                      style: const TextStyle(fontSize: 16, color: Colors.black),
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
                  ),
              ]),
            ),
          )),
    );
  }
}
