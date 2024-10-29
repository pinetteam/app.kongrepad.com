import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kongrepad/AlertService.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/Models/Hall.dart';
import 'package:kongrepad/Models/Program.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Translation maps for day and month names
Map<String, String> dayTranslations = {
  'Monday': 'Pazartesi',
  'Tuesday': 'Salı',
  'Wednesday': 'Çarşamba',
  'Thursday': 'Perşembe',
  'Friday': 'Cuma',
  'Saturday': 'Cumartesi',
  'Sunday': 'Pazar',
};

Map<String, String> monthTranslations = {
  'January': 'Ocak',
  'February': 'Şubat',
  'March': 'Mart',
  'April': 'Nisan',
  'May': 'Mayıs',
  'June': 'Haziran',
  'July': 'Temmuz',
  'August': 'Ağustos',
  'September': 'Eylül',
  'October': 'Ekim',
  'November': 'Kasım',
  'December': 'Aralık',
};

String translateDateToTurkish(String englishDate) {
  String translatedDate = englishDate;

  // Translate day names
  dayTranslations.forEach((english, turkish) {
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, turkish);
    }
  });

  // Translate month names
  monthTranslations.forEach((english, turkish) {
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, turkish);
    }
  });

  return translatedDate;
}

// Calculate the difference between two time strings
double calculateTimeDifference(String start, String end) {
  DateFormat format = DateFormat("HH:mm");
  DateTime startTime = format.parse(start);
  DateTime endTime = format.parse(end);
  return endTime.difference(startTime).inMinutes / 60;
}

class ProgramMailView extends StatefulWidget {
  const ProgramMailView({super.key, required this.programDay, required this.hallId});

  final ProgramDay programDay;
  final int hallId;

  @override
  State<ProgramMailView> createState() => _ProgramMailViewState(programDay, hallId);
}

class _ProgramMailViewState extends State<ProgramMailView> {
  ProgramDay? programDay;
  Hall? hall;
  final int hallId;
  Set<int> documents = {}; // Seçilen belgeler burada saklanır
  bool _sending = false;
  bool _loading = true;

  _ProgramMailViewState(this.programDay, this.hallId);

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse('https://app.kongrepad.com/api/v1/hall/$hallId');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final hallJson = HallJSON.fromJson(jsonData);
        setState(() {
          hall = hallJson.data;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e'); // LOG: Veri çekme hatası
    }
  }

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

    return Scaffold(
      backgroundColor: AppConstants.programBackgroundYellow,
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : SafeArea(
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Üst kısımdaki başlık
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppConstants.buttonYellow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/icon/chevron.left.svg',
                              color: AppConstants.buttonYellow,
                              height: screenHeight * 0.03,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        "Mail Gönder",
                        style: TextStyle(fontSize: 25, color: Colors.white),
                      ),
                      const SizedBox(width: 55), // Ortalamayı sağlamak için.
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                // Ana salon ve program günü kısmı
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.programBackgroundYellow,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          hall?.title.toString() ?? "",
                          style: const TextStyle(fontSize: 23, color: Colors.black),
                        ),
                        Text(
                          translateDateToTurkish(programDay!.day.toString()), // Gün bilgisi Türkçeye çevriliyor
                          style: const TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),

                // Program listesi (Scrollable yapı)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: programDay?.programs?.length ?? 0,
                  itemBuilder: (context, index) {
                    final program = programDay!.programs![index];

                    // Calculate time difference for the height of each program
                    double heightFactor = calculateTimeDifference(program.startAt!, program.finishAt!);

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Zaman ve çizgi bölümü
                                Container(
                                  width: screenWidth * 0.25,
                                  decoration: BoxDecoration(
                                    color: AppConstants.programBackgroundYellow,
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        program.startAt ?? "",
                                        style: const TextStyle(fontSize: 18, color: AppConstants.backgroundBlue),
                                      ),
                                      Expanded(
                                        child: Container(
                                          width: 2.0,
                                          color: Colors.black,
                                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                                        ),
                                      ),
                                      Text(
                                        program.finishAt ?? "",
                                        style: const TextStyle(fontSize: 18, color: AppConstants.backgroundBlue),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Sağ kutucuk genişliği ve içerikler
                                Flexible(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppConstants.hallsButtonBlue,
                                      border: Border.all(color: Colors.black),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          program.title.toString(),
                                          style: const TextStyle(fontSize: 18, color: Colors.black),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        if (program.chairs!.isNotEmpty)
                                          Text(
                                            (program.chairs!.length == 1
                                                ? "Moderatör: "
                                                : "Moderatörler: ") +
                                                program.chairs!.map((chair) => chair.fullName).join(', '),
                                            style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (program.description != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              program.description.toString(),
                                              style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                        // Oturum belgeleri (checkbox)
                                        if (program.sessions!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Column(
                                              children: program.sessions!.map((session) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.black),
                                                    borderRadius: BorderRadius.circular(8),
                                                    color: Colors.white,
                                                  ),
                                                  child: CheckboxListTile(
                                                    title: Text(
                                                      session.title!,
                                                      style: TextStyle(
                                                        fontSize: screenWidth * 0.04,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    value: documents.contains(session.documentId),
                                                    onChanged: (bool? selected) {
                                                      setState(() {
                                                        if (selected == true) {
                                                          documents.add(session.documentId!);
                                                        } else {
                                                          documents.remove(session.documentId!);
                                                        }
                                                      });
                                                    },
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Mail Gönder Butonu
                Container(
                  width: screenWidth,
                  height: screenHeight * 0.1,
                  decoration: BoxDecoration(color: AppConstants.buttonYellow),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.programBackgroundYellow,
                        ),
                        onPressed: _sending
                            ? null
                            : () {
                          _sendMail();
                        },
                        child: _sending
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icon/envelope.open.fill.svg',
                              color: Colors.black,
                              height: screenHeight * 0.02,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Gönder',
                              style: TextStyle(fontSize: 20, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMail() async {
    setState(() {
      _sending = true;
    });

    print('Mail Gönderme Başladı'); // LOG: Mail gönderme işlemi başladı

    final url = Uri.parse('https://app.kongrepad.com/api/v1/mail');
    print('URL: $url'); // LOG: URL'yi yazdır

    final body = jsonEncode({
      'documents': "[${documents.map((int e) => e.toString()).join(",")}]",
    });

    print('İstek Gövdesi: $body'); // LOG: İstek gövdesi yazdır

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Token: $token'); // LOG: Token yazdır

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Yanıt Durum Kodu: ${response.statusCode}'); // LOG: HTTP durum kodu
      print('Yanıt Gövdesi: ${response.body}'); // LOG: Yanıt gövdesi

      final jsonResponse = jsonDecode(response.body);
      print('Çözülmüş Yanıt: $jsonResponse'); // LOG: JSON yanıtı

      if (jsonResponse['status']) {
        AlertService().showAlertDialog(
          context,
          title: 'Başarılı',
          content:
          "Paylaşıma izin verilen sunumlardan talep ettikleriniz kongreden sonra tarafınıza mail olarak gönderilecektir.",
        );
        Navigator.of(context).pop();
      } else {
        print('Hata Mesajı: ${jsonResponse['message']}'); // LOG: Hata mesajı
        AlertService().showAlertDialog(
          context,
          title: 'Hata',
          content: 'Bir hata meydana geldi.',
        );
      }
    } catch (e) {
      print('Mail Gönderme Hatası: $e'); // LOG: Hata durumunu yazdır
    }

    setState(() {
      _sending = false;
    });
  }
}
