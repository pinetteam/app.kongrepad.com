import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/Hall.dart';
import '../models/Program.dart';
import '../utils/app_constants.dart';

// Map for translating English day names to Turkish
Map<String, String> dayTranslations = {
  'Monday': 'Pazartesi',
  'Tuesday': 'Salı',
  'Wednesday': 'Çarşamba',
  'Thursday': 'Perşembe',
  'Friday': 'Cuma',
  'Saturday': 'Cumartesi',
  'Sunday': 'Pazar',
};

// Map for translating English month names to Turkish
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

// Function to translate day and month names to Turkish
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

class ProgramView extends StatefulWidget {
  const ProgramView(
      {super.key, required this.programDay, required this.hallId});

  final ProgramDay programDay;
  final int hallId;

  @override
  State<ProgramView> createState() => _ProgramViewState(programDay, hallId);
}

class _ProgramViewState extends State<ProgramView> {
  ProgramDay? programDay;
  Hall? hall;
  final int hallId;
  bool _loading = true;

  _ProgramViewState(this.programDay, this.hallId);

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
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  String getLogoUrl(Program program) {
    return "https://app.kongrepad.com/storage/program-logos/${program.logoName}.${program.logoExtension}";
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
                          Padding(
                            padding: const EdgeInsets.only(right: 80),
                            child: const Text(
                              "Bilimsel Program",
                              style:
                                  TextStyle(fontSize: 25, color: Colors.white),
                            ),
                          ),
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
                              style: const TextStyle(
                                  fontSize: 25, color: Colors.black),
                            ),
                            Text(
                              translateDateToTurkish(programDay!.day
                                  .toString()), // Translate day to Turkish
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Program listesi
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: programDay?.programs?.length ?? 0,
                      itemBuilder: (context, index) {
                        final program = programDay!.programs![index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Zaman dilimi ve çizgi bölümü
                                    SizedBox(
                                      width: screenWidth * 0.3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppConstants
                                              .programBackgroundYellow,
                                          border:
                                              Border.all(color: Colors.black),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0,
                                                  3), // Gölgeyi aşağıya verir
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            Text(
                                              program.startAt.toString(),
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  color: AppConstants
                                                      .backgroundBlue),
                                            ),
                                            Expanded(
                                              child: Container(
                                                width: 2.0, // Çizgi genişliği
                                                color:
                                                    Colors.black, // Çizgi rengi
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4.0),
                                              ),
                                            ),
                                            Text(
                                              program.finishAt.toString(),
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  color: AppConstants
                                                      .backgroundBlue),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppConstants.hallsButtonBlue,
                                          border:
                                              Border.all(color: Colors.black),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0,
                                                  3), // Gölgeyi aşağıya verir
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (program.logoName != null)
                                              // Logo gösterimi - Responsive hale getirme
                                              Image.network(
                                                getLogoUrl(program),
                                                height: screenHeight *
                                                    0.15, // Yükseklik ayarı (responsive)
                                                width: screenWidth *
                                                    0.65, // Genişlik ayarı (responsive)
                                                fit: BoxFit
                                                    .contain, // Logo kutuya sığacak şekilde boyutlandırılır
                                              ),
                                            const SizedBox(height: 8),
                                            Text(
                                              program.title.toString(),
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.black),
                                            ),
                                            if (program.chairs!.isNotEmpty)
                                              Text(
                                                (program.chairs!.length == 1
                                                        ? "Moderatör: "
                                                        : "Moderatörler: ") +
                                                    program.chairs!
                                                        .map((chair) =>
                                                            chair.fullName)
                                                        .join(', '),
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    color:
                                                        CupertinoColors.black),
                                              ),
                                            if (program.description != null)
                                              Text(
                                                program.description.toString(),
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    color:
                                                        CupertinoColors.black),
                                              ),

                                            // Sessions bölümü - Oturumlar ve saatleri
                                            if (program.sessions != null)
                                              Column(
                                                children: program.sessions!
                                                    .map((session) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              '${session.startAt} - ${session.finishAt}', // Oturum saatleri
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 10),
                                                            Expanded(
                                                              child: Text(
                                                                session.title ??
                                                                    '',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  color:
                                                                      CupertinoColors
                                                                          .black,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (session
                                                                .description !=
                                                            null)
                                                          Text(
                                                            session
                                                                .description!,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  CupertinoColors
                                                                      .black,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),

                                            // Debate bölümü
                                            if (program.debates != null)
                                              Column(
                                                children: program.debates!
                                                    .map((debate) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          debate.title!,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        if (debate
                                                                .description !=
                                                            null)
                                                          Text(
                                                            debate.description!,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  CupertinoColors
                                                                      .black,
                                                            ),
                                                          ),
                                                        // Debate takımları
                                                        for (var team
                                                            in debate.teams ??
                                                                [])
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 8.0),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  team.title!,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                if (team.description !=
                                                                    null)
                                                                  Text(
                                                                    team.description!,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: CupertinoColors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
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
                  ],
                ),
              ),
            ),
    );
  }
}
