import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/Program.dart';
import '../utils/app_constants.dart';
import 'ProgramView.dart';

String translateDate(String englishDate, BuildContext context) {
  String translatedDate = englishDate;

  dayTranslations.forEach((english, _) {
    final translation =
    AppLocalizations.of(context).translate(english.toLowerCase());
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, translation);
    }
  });

  // Translate month names
  monthTranslations.forEach((english, _) {
    final translation =
    AppLocalizations.of(context).translate(english.toLowerCase());
    if (englishDate.contains(english)) {
      translatedDate = translatedDate.replaceAll(english, translation);
    }
  });

  return translatedDate;
}

class ProgramDaysView extends StatefulWidget {
  const ProgramDaysView({super.key, required this.hallId});

  final int hallId;

  @override
  State<ProgramDaysView> createState() => _ProgramDaysViewState(hallId);
}

class _ProgramDaysViewState extends State<ProgramDaysView> {
  final int hallId;
  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<ProgramDay>? programDays;

  _ProgramDaysViewState(this.hallId);

  @override
  void initState() {
    super.initState();
    print('ProgramDaysView - initState başladı, hallId: $hallId');
    getData();
  }

  // ProgramDaysView.dart - getData metodunu bu ile değiştir:

  // ProgramDaysView.dart - API'yi Meeting Schedule ile değiştir:

  Future<void> getData() async {
    print('ProgramDaysView - getData başladı');
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('ProgramDaysView - Token bulunamadı');
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Oturum süresi dolmuş';
      });
      return;
    }

    try {
      // ✅ Mevcut API endpoint'ini kullan
      final url = Uri.parse('https://api.kongrepad.com/api/v1/meetings/6/schedule');
      print('ProgramDaysView - API URL: $url');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('ProgramDaysView - API Status: ${response.statusCode}');
      print('ProgramDaysView - API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('ProgramDaysView - JSON parsed successfully');

        if (jsonData['success'] == true && jsonData['data'] != null) {
          var scheduleData = jsonData['data'];

          // Schedule data'dan hall'a ait programları filtrele
          await _processScheduleData(scheduleData);
          return;
        } else {
          throw Exception(jsonData['message'] ?? 'API yanıtı başarısız');
        }
      } else if (response.statusCode == 401) {
        print('ProgramDaysView - Unauthorized');
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Oturum süresi dolmuş';
        });
      } else if (response.statusCode == 404) {
        print('ProgramDaysView - Schedule bulunamadı');
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Program bilgileri bulunamadı';
        });
      } else {
        print('ProgramDaysView - API Error: ${response.statusCode}');
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Program yüklenirken hata oluştu (${response.statusCode})';
        });
      }
    } catch (e, stackTrace) {
      print('ProgramDaysView - Exception: $e');
      print('ProgramDaysView - StackTrace: $stackTrace');
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Bağlantı hatası: $e';
      });
    }
  }

// Schedule data'sını işle
  // _processScheduleData metodunu bu ile değiştir:

  // _processScheduleData metodunu bu ile değiştir:

  Future<void> _processScheduleData(dynamic scheduleData) async {
    try {
      print('ProgramDaysView - Schedule data işleniyor...');
      print('ProgramDaysView - Schedule data type: ${scheduleData.runtimeType}');

      List<dynamic> allPrograms = [];

      if (scheduleData is Map) {
        print('ProgramDaysView - Schedule keys: ${scheduleData.keys}');

        // ✅ Mevcut API formatına göre: data.schedule.days[].halls[].hall.programs[]
        if (scheduleData.containsKey('schedule')) {
          var schedule = scheduleData['schedule'];
          print('ProgramDaysView - Schedule found: ${schedule.runtimeType}');

          if (schedule is Map && schedule.containsKey('days')) {
            var days = schedule['days'];
            print('ProgramDaysView - Days found: ${days.runtimeType}, length: ${days.length}');

            if (days is List) {
              for (var day in days) {
                print('ProgramDaysView - Processing day: ${day['date']}');

                if (day['halls'] != null) {
                  var halls = day['halls'] as List;
                  print('ProgramDaysView - Day has ${halls.length} halls');

                  for (var hallData in halls) {
                    if (hallData['hall'] != null) {
                      var hall = hallData['hall'];
                      print('ProgramDaysView - Checking hall ${hall['id']} (target: ${widget.hallId})');

                      // Hall ID'si eşleşiyor mu kontrol et
                      if (hall['id'] == widget.hallId && hall['programs'] != null) {
                        var programs = hall['programs'] as List;
                        print('ProgramDaysView - ✅ Hall ${widget.hallId} için ${programs.length} program bulundu');
                        allPrograms.addAll(programs);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      print('ProgramDaysView - Toplam ${allPrograms.length} program bulundu');

      if (allPrograms.isNotEmpty) {
        await _createProgramDaysFromPrograms(allPrograms);
      } else {
        print('ProgramDaysView - Hall ${widget.hallId} için program bulunamadı');

        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Hall ${widget.hallId} için program bulunamadı.\n\nLütfen farklı bir salon deneyin.';
        });
      }
    } catch (e, stackTrace) {
      print('ProgramDaysView - Schedule processing error: $e');
      print('ProgramDaysView - StackTrace: $stackTrace');
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Program verileri işlenirken hata oluştu: $e';
      });
    }
  }
// Program listesinden program days oluştur
  Future<void> _createProgramDaysFromPrograms(List<dynamic> programs) async {
    try {
      // Program listesini günlere göre grupla
      Map<String, List<dynamic>> programsByDay = {};

      for (var program in programs) {
        if (program is Map && program['start_at'] != null) {
          try {
            DateTime startDate = DateTime.parse(program['start_at']);
            String dayKey = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";

            if (!programsByDay.containsKey(dayKey)) {
              programsByDay[dayKey] = [];
            }
            programsByDay[dayKey]!.add(program);
          } catch (e) {
            print('ProgramDaysView - Tarih parse hatası: $e');
          }
        }
      }

      // Program days listesi oluştur
      List<ProgramDay> generatedProgramDays = [];

      programsByDay.forEach((dayKey, dayPrograms) {
        if (dayPrograms.isNotEmpty) {
          try {
            DateTime dayDate = DateTime.parse(dayPrograms.first['start_at']);

            // Türkçe tarih formatı
            List<String> months = [
              '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
              'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
            ];

            List<String> days = [
              'Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'
            ];

            String dayName = days[dayDate.weekday % 7];
            String monthName = months[dayDate.month];
            String formattedDay = "$dayName, ${dayDate.day} $monthName ${dayDate.year}";

            // Program objelerini oluştur
            List<Program> convertedPrograms = [];
            for (var programData in dayPrograms) {
              try {
                Program program = Program.fromJson(programData);
                convertedPrograms.add(program);
              } catch (e) {
                print('ProgramDaysView - Program parse hatası: $e');
              }
            }

            if (convertedPrograms.isNotEmpty) {
              ProgramDay programDay = ProgramDay(
                day: formattedDay,
                programs: convertedPrograms,
              );
              generatedProgramDays.add(programDay);
            }
          } catch (e) {
            print('ProgramDaysView - Program day oluşturma hatası: $e');
          }
        }
      });

      // Tarihe göre sırala
      generatedProgramDays.sort((a, b) {
        try {
          DateTime dateA = DateTime.parse(a.programs!.first.startAt!);
          DateTime dateB = DateTime.parse(b.programs!.first.startAt!);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        programDays = generatedProgramDays;
        _loading = false;
      });

      print('ProgramDaysView - ✅ ${generatedProgramDays.length} program günü oluşturuldu');
    } catch (e) {
      print('ProgramDaysView - Program days oluşturma hatası: $e');
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Program günleri oluşturulurken hata oluştu';
      });
    }
  }
// Program data'sını işleme metodu
  void _processProgramData(dynamic programData) {
    try {
      print('ProgramDaysView - Program data işleniyor...');

      if (programData is List && programData.isNotEmpty) {
        // Program listesini program days'e çevir
        Map<String, List<dynamic>> programsByDay = {};

        for (var program in programData) {
          if (program is Map && program['start_at'] != null) {
            // Program tarihini al
            DateTime startDate = DateTime.parse(program['start_at']);
            String dayKey = "${startDate.day}-${startDate.month}-${startDate.year}";

            if (!programsByDay.containsKey(dayKey)) {
              programsByDay[dayKey] = [];
            }
            programsByDay[dayKey]!.add(program);
          }
        }

        // Program days listesi oluştur
        List<ProgramDay> generatedProgramDays = [];
        programsByDay.forEach((dayKey, programs) {
          if (programs.isNotEmpty) {
            DateTime dayDate = DateTime.parse(programs.first['start_at']);
            String formattedDay = "${dayDate.day} ${_getMonthName(dayDate.month)} ${dayDate.year}";

            // ProgramDay oluştur (bu kısmı Program model'inize göre ayarlayın)
            ProgramDay programDay = ProgramDay(
              day: formattedDay,
              programs: programs.map((p) => Program.fromJson(p)).toList(),
            );
            generatedProgramDays.add(programDay);
          }
        });

        if (generatedProgramDays.isNotEmpty) {
          setState(() {
            programDays = generatedProgramDays;
            _loading = false;
          });
          print('ProgramDaysView - ✅ ${generatedProgramDays.length} program günü oluşturuldu');
          return;
        }
      }

      throw Exception('Program data işlenemedi');
    } catch (e) {
      print('ProgramDaysView - Program data işleme hatası: $e');
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Program verileri işlenirken hata oluştu';
      });
    }
  }

// Ay ismi helper
  String _getMonthName(int month) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    return Scaffold(
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : _hasError
          ? Container(
        decoration: const BoxDecoration(
          color: AppConstants.programBackgroundYellow,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[700],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Bir hata oluştu',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: getData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.buttonYellow,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tekrar Dene'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Geri Dön',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      )
          : Container(
        decoration: const BoxDecoration(
          color: AppConstants.programBackgroundYellow,
        ),
        height: screenHeight,
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                height: screenHeight * 0.1,
                decoration: const BoxDecoration(
                  color: AppConstants.buttonYellow,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: screenWidth,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: screenHeight * 0.04,
                          width: screenHeight * 0.04,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate("select_day"),
                            style: const TextStyle(
                              fontSize: 25,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  height: screenHeight * 0.65,
                  width: screenWidth,
                  child: Column(
                    children: programDays?.map((day) {
                      String translatedDay =
                      translateDateToTurkish(day.day!);

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                              WidgetStateProperty.all<Color>(
                                AppConstants.hallsButtonBlue,
                              ),
                              foregroundColor:
                              WidgetStateProperty.all<Color>(
                                AppConstants.backgroundBlue,
                              ),
                              padding: WidgetStateProperty.all<
                                  EdgeInsetsGeometry>(
                                const EdgeInsets.all(12),
                              ),
                              shape: WidgetStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            onPressed: () {
                              print(
                                  'ProgramDaysView - Program günü seçildi: $translatedDay');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProgramView(
                                        programDay: day,
                                        hallId: hallId,
                                      ),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: screenWidth * 0.7,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding:
                                    const EdgeInsets.all(2),
                                    child: SvgPicture.asset(
                                      'assets/icon/chevron.right.2.svg',
                                      color: AppConstants
                                          .backgroundBlue,
                                      height: screenHeight * 0.03,
                                    ),
                                  ),
                                  SizedBox(
                                    width: screenWidth * 0.03,
                                  ),
                                  Flexible(
                                    child: Center(
                                      child: Text(
                                        translatedDay,
                                        style: const TextStyle(
                                          fontSize: 20,
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
                    }).toList() ??
                        [],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}