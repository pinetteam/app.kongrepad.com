import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kongrepad/Models/Announcement.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {


  Future<void> getData() async {
    print('getData: Başladı');  // Fonksiyonun başladığını loglayın
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Token kontrolü
    if (token == null) {
      print('getData: Token bulunamadı');  // Token bulunamadıysa hata yazdır
      return;
    }

    print('getData: Token bulundu: $token');  // Token bulunduysa token'ı loglayın

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/announcement');
      print('getData: API isteği gönderiliyor...');  // API isteği başlatıldığını loglayın

      // HTTP isteğini yapın
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print('getData: API isteği tamamlandı, statusCode: ${response.statusCode}');  // API isteğinin sonucunu loglayın
      print(response.body);
      // Yanıt kontrolü
      if (response.statusCode == 200) {
        print('getData: Yanıt başarılı, body: ${response.body}');  // Başarılı yanıt durumunda JSON yanıtını loglayın

        // Gelen yanıtı tam olarak görmek için ayrıntılı olarak loglayalım
        final jsonData = jsonDecode(response.body);
        print('getData: Çözülen JSON: $jsonData');  // JSON verisini loglayın

        // API'den dönen "data" alanını ayrıntılı loglayalım
        if (jsonData['data'] == null) {
          print('getData: JSON içindeki data null');
        } else {
          print('getData: JSON içindeki data uzunluğu: ${jsonData['data'].length}');
          print('getData: JSON içeriği: ${jsonData['data']}'); // Data içeriğini tam olarak logla
        }

        // Gelen verileri modelimize çevirelim
        final announcementsJson = AnnouncementsJSON.fromJson(jsonData);

        // announcementsJson.data'nın null olup olmadığını kontrol edin
        if (announcementsJson.data == null || announcementsJson.data!.isEmpty) {
          print('getData: announcementsJson data boş ya da null, API duyuruları döndürmedi.');
        } else {
          print('getData: announcementsJson data dolu, duyuru sayısı: ${announcementsJson.data!.length}');
        }

        setState(() {
          announcements = announcementsJson.data ?? [];  // Null ise boş bir liste atıyoruz
          _loading = false;
        });

        print('getData: Duyurular başarıyla alındı, duyuru sayısı: ${announcements?.length}');
      } else {
        print('getData: Yanıt başarısız, statusCode: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      print('getData: Hata: $e');  // Hata durumunda hata mesajını loglayın
    }
  }


  List<Announcement>? announcements;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    getData();
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
              valueColor:
              AlwaysStoppedAnimation<Color>(Colors.white),
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
                  child: Container(
                    width: screenWidth,
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
                            ]),
                      ],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Container(
                    height: screenHeight * 0.775,
                    width: screenWidth,
                    child: Column(
                      children: announcements != null
                          ? announcements!.map((announcement) {
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: Container(
                            alignment: Alignment.topLeft,
                            width: screenWidth * 0.9,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icon/bell.svg',
                                      color: Colors.black,
                                      height: screenHeight * 0.03,
                                    ),
                                    Text(
                                      announcement.title.toString(),
                                      style: const TextStyle(
                                          fontSize: 20, color: Colors.black),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 20,
                                  thickness: 1,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList()
                          : [],
                    ),
                  ),
                ),
                Container(
                  width: screenWidth,
                  height: screenHeight * 0.1,
                  decoration: BoxDecoration(color: Colors.redAccent),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey),
                        onPressed: () {
                          //todo bildirimleri temizle
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icon/bell.svg',
                              color: Colors.black,
                              height: screenHeight * 0.02,
                            ),
                            SizedBox(
                              width: screenWidth*0.01,
                            ),
                            const Text(
                              'Tüm Duyuruları Okudum',
                              style:
                              TextStyle(fontSize: 20, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          )),
    );
  }
}
