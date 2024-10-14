import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/Models/Debate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import 'PusherService.dart';

class DebateView extends StatefulWidget {
  const DebateView({super.key, required this.hallId});

  final int hallId;

  @override
  State<DebateView> createState() => _DebateViewState(hallId);
}

class _DebateViewState extends State<DebateView> {
  int? hallId;
  Debate? debate;
  bool _sending = false;
  bool _loading = true;

  _DebateViewState(this.hallId);

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/hall/$hallId/active-debate');
      print("Requesting data from: $url"); // Log: API isteği URL'si
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print("Response status code: ${response.statusCode}"); // Log: API durumu

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Response data: $jsonData"); // Log: API cevabı
        final debateJson = DebateJSON.fromJson(jsonData);
        setState(() {
          debate = debateJson.data;
          _loading = false;
        });
      } else {
        print("Error: ${response.body}"); // Log: API hata cevabı
      }
    } catch (e) {
      print('Error fetching data: $e'); // Log: Yakalanan hata
    }
  }

  Future<void> _subscribeToPusher() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
      await pusher.init(apiKey: "314fc649c9f65b8d7960", cluster: "eu");
      await pusher.connect();

      print("Subscribing to channel: meeting-${widget.hallId}-attendee"); // Log: Kanal abonesi

      await pusher.subscribe(channelName: 'meeting-${widget.hallId}-attendee');

      pusher.onEvent = (PusherEvent event) {
        if (event.data == null || event.data!.isEmpty) {
          // Veri yoksa direkt geri dön.
          return;
        }

        if (event.eventName == 'debate-activated') {
          try {
            final jsonData = jsonDecode(event.data!);

            // hall_id kontrolü
            if (jsonData.containsKey('hall_id') && jsonData['hall_id'] == hallId) {
              // Eğer hall_id eşleşiyorsa, sayfaya yönlendirme yap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DebateView(hallId: jsonData['hall_id'])),
              );
            }
          } catch (e) {
            // JSON ayrıştırma hatası varsa sessizce hatayı yoksay
            return;
          }
        }
      };


    }
  }

  @override
  void initState() {
    super.initState();
    getData();
    _subscribeToPusher(); // Pusher aboneliği başlatılıyor
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
            : Container(
          height: screenHeight,
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                height: screenHeight * 0.1,
                decoration: const BoxDecoration(
                  color: AppConstants.backgroundBlue,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white, // Border color
                      width: 2, // Border width
                    ),
                  ),
                ),
                child: Container(
                  width: screenWidth,
                  child: Text(
                    "Anketler",
                    style: TextStyle(fontSize: 25, color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Anketlerimizi doldurarak bize yardımcı olabilirsiniz",
                style: TextStyle(fontSize: 25, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: debate != null
                    ? Container(
                  height: screenHeight * 0.65,
                  width: screenWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: debate!.teams!.map((team) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                              MaterialStateProperty.all<Color>(
                                  AppConstants.buttonLightPurple),
                              foregroundColor:
                              MaterialStateProperty.all<Color>(
                                  Colors.white),
                              padding: MaterialStateProperty.all<
                                  EdgeInsetsGeometry>(
                                const EdgeInsets.all(12),
                              ),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            onPressed: () {
                              _sendAnswer(team.id!);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                team.logoName != null
                                    ? Image.network(
                                  'https://app.kongrepad.com/storage/team-logos/${team.logoName}.${team.logoExtension}',
                                  width: 150, // Adjust image width
                                  height: 150, // Adjust image height
                                  fit: BoxFit.contain,
                                )
                                    : Text(team.title.toString()),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
                    : Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendAnswer(int answerId) async {
    setState(() {
      _sending = true;
    });
    final url = Uri.parse(
        'https://app.kongrepad.com/api/v1/debate/${debate?.id!}/debate-vote');
    final body = jsonEncode({
      'option': answerId,
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    http
        .post(
      url,
      headers: {
        'Authorization': 'Bearer ${prefs.getString('token')}',
        'Content-Type': 'application/json',
      },
      body: body,
    )
        .then((response) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        Navigator.of(context).pop();
      }
      setState(() {
        _sending = false;
      });
    }).catchError((error) {
      print(error);
      setState(() {
        _sending = false;
      });
    });
  }
}
