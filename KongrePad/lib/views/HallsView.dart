import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/Hall.dart';
import '../utils/app_constants.dart';
import 'SessionView.dart';
import 'DebateView.dart';
import 'KeypadView.dart';

class HallsView extends StatefulWidget {
  const HallsView({super.key, required this.type});

  final String type;

  @override
  State<HallsView> createState() => _HallsViewState(type);
}

class _HallsViewState extends State<HallsView> {
  Future<void> getData() async {
    print('HallsView - getData başladı');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse('https://api.kongrepad.com/api/v1/halls/list');
      print('HallsView - API çağrısı yapılıyor: $url');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('HallsView - API yanıtı: ${response.statusCode}');
      print('HallsView - API yanıt body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final hallsJson = HallsJSON.fromJson(jsonData);
          if (hallsJson.data != null && hallsJson.data!.isNotEmpty) {
            setState(() {
              halls = hallsJson.data;
              _loading = false;
            });
            print(
                'HallsView - Veriler başarıyla yüklendi. Hall sayısı: ${halls?.length}');
          } else {
            print('HallsView - Veri bulunamadı');
            setState(() {
              _loading = false;
              _hasError = true;
              _errorMessage = 'Salon bulunamadı';
            });
          }
        } else {
          throw Exception(jsonData['message'] ?? 'API yanıtı başarısız');
        }
      } else if (response.statusCode == 401) {
        // Token geçersiz, login sayfasına yönlendir
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        print('HallsView - API hatası: ${response.statusCode}');
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage =
              'Salonlar yüklenirken bir hata oluştu (${response.statusCode})';
        });
      }
    } catch (e, stackTrace) {
      print('HallsView - Hata: $e');
      print('HallsView - Stack trace: $stackTrace');
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Bir hata oluştu: $e';
      });
    }
  }

  final String type;
  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Hall>? halls;

  _HallsViewState(this.type);

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
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage ?? 'Bir hata oluştu',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _loading = true;
                                _hasError = false;
                                _errorMessage = null;
                              });
                              getData();
                            },
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      width: screenWidth,
                      height: screenHeight,
                      decoration: const BoxDecoration(
                        color: AppConstants.backgroundBlue,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: screenWidth,
                            height: screenHeight * 0.1,
                            decoration: const BoxDecoration(
                              color: AppConstants.backgroundBlue,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: SvgPicture.asset(
                                    'assets/icon/chevron.left.svg',
                                    colorFilter: const ColorFilter.mode(
                                        Colors.white, BlendMode.srcIn),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('halls'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 40),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: screenWidth,
                              decoration: const BoxDecoration(
                                color: AppConstants.backgroundBlue,
                              ),
                              child: ListView.builder(
                                itemCount: halls?.length ?? 0,
                                itemBuilder: (context, index) {
                                  final hall = halls![index];
                                  return GestureDetector(
                                    onTap: () {
                                      if (type == "session") {
                                        print(
                                            "HallsView - SessionView'a yönlendiriliyor. HallId: ${hall.id}");
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => SessionView(
                                                  hallId: hall.id!)),
                                        );
                                      } else if (type == "debate") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  DebateView(hallId: hall.id!)),
                                        );
                                      } else if (type == "keypad") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  KeypadView(hallId: hall.id!)),
                                        );
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppConstants.hallsButtonBlue,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              hall.title ?? '',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SvgPicture.asset(
                                            'assets/icon/chevron.right.svg',
                                            colorFilter: const ColorFilter.mode(
                                                Colors.black, BlendMode.srcIn),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
    );
  }
}
