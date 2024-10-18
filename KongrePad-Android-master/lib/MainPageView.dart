// MainPageView.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kongrepad/AlertService.dart';
import 'package:kongrepad/AnnouncementsView.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:kongrepad/AskQuestionView.dart';
import 'package:kongrepad/HallsView.dart';
import 'package:kongrepad/main.dart';
import 'package:kongrepad/ProfileView.dart';
import 'package:kongrepad/ProgramDaysForMailView.dart';
import 'package:kongrepad/ProgramDaysView.dart';
import 'package:kongrepad/ScoreGameView.dart';
import 'package:kongrepad/SessionView.dart';
import 'package:kongrepad/SurveysView.dart';
import 'package:kongrepad/VirtualStandView.dart';
import 'package:kongrepad/Models/Meeting.dart';
import 'package:kongrepad/Models/Participant.dart';
import 'package:kongrepad/Models/VirtualStand.dart';
import 'package:pusher_beams/pusher_beams.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kongrepad/DebateView.dart';
import 'KeypadView.dart';
import 'Models/Keypad.dart';

class LowerHalfEllipse extends StatelessWidget   {
  final double width;
  final double height;

  const LowerHalfEllipse(this.width, this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: ClipRect(
        child: CustomPaint(
          painter: LowerHalfEllipsePainter(),
          size: Size(width, height), // Set the size explicitly
        ),
      ),
    );
  }
}

class LowerHalfEllipsePainter extends CustomPainter   {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(
        -0.5 * size.width, -1 * size.height, size.width * 2, size.height * 2);

    canvas.drawArc(rect, 0, 180 * (3.14159265359 / 180), true, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class MainPageView extends StatefulWidget  {
  const MainPageView({super.key, required this.title});

  final String title;

  @override
  State<MainPageView> createState() => _MainPageViewState();
}

class _MainPageViewState extends State<MainPageView>  with WidgetsBindingObserver{
  Meeting? meeting;
  Participant? participant;
  List<VirtualStand>? virtualStands;
  bool _loading = true;
  PusherChannelsFlutter? pusher;

  Future<void> logOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("token");
  }

  Future<bool> checkForKeypad(int hallId) async {
    print('Checking for an active keypad for hallId: $hallId');

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('No token found. Aborting keypad check.');
      return false;
    }

    try {
      final url =
      Uri.parse('http://app.kongrepad.com/api/v1/hall/$hallId/active-keypad');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Keypad JSON response: $jsonData');

        final keypadJson = KeypadJSON.fromJson(jsonData);
        if (keypadJson.data != null) {
          print('Active keypad found: ${keypadJson.data}');
          return true; // Active keypad exists
        } else {
          print('No active keypad found.');
          return false; // No active keypad
        }
      } else {
        print('Error fetching keypad data: ${response.statusCode}');
        return false; // Error occurred
      }
    } catch (e) {
      print('Error while checking for keypad: $e');
      return false; // Error occurred
    }
  }

  Future<void> getData() async {
    print("getData fonksiyonu başladı");

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') == null) {
      print("Token bulunamadı, LoginView'a yönlendiriliyor");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
      return;
    }

    final token = prefs.getString('token');
    print("Token bulundu: $token");

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/meeting');
      print("Meeting verisi çekiliyor...");
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print(
          "Meeting API isteği tamamlandı. Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Meeting verisi başarıyla alındı: $jsonData");
        final meetingJson = MeetingJSON.fromJson(jsonData);

        setState(() {
          meeting = meetingJson.data;
        });

        if (meeting == null) {
          print("Meeting boş, LoginView'a yönlendiriliyor...");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
          );
        } else {
          print("Meeting ID: ${meeting!.id}");
        }
      } else {
        print("Meeting verisi yüklenemedi, LoginView'a yönlendiriliyor");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    } catch (e) {
      print("Error in meeting API request: $e");
    }

    if (meeting != null && meeting!.id != null) {
      final meetingId = meeting!.id.toString();
      print("Pusher Beams abone olma işlemi başlıyor. Meeting ID: $meetingId");

      PusherBeams beamsClient = PusherBeams.instance;

      await beamsClient.clearDeviceInterests(); // Önceki interest'ler temizleniyor
      print("Pusher Beams önceki interest'ler temizlendi.");

      await beamsClient.addDeviceInterest('debug-meeting_$meetingId');
      print("Pusher Beams yeni interest eklendi: debug-meeting_$meetingId");
    }

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/participant');
      print("Participant verisi çekiliyor...");
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print(
          "Participant API isteği tamamlandı. Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Participant verisi başarıyla alındı: $jsonData");
        final participantJson = ParticipantJSON.fromJson(jsonData);

        setState(() {
          participant = participantJson.data;
          _subscribeToPusher(); // Pusher aboneliğini başlatıyoruz
        });
      } else {
        print("Participant verisi yüklenemedi, LoginView'a yönlendiriliyor");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    } catch (e) {
      print("Error in participant API request: $e");
    }

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/virtual-stand');
      print("Virtual stand verisi çekiliyor...");
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print(
          "Virtual stand API isteği tamamlandı. Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Virtual stand verisi başarıyla alındı: $jsonData");
        final virtualStandsJson = VirtualStandsJSON.fromJson(jsonData);

        setState(() {
          virtualStands = virtualStandsJson.data;
          _loading = false;
        });
      } else {
        print("Virtual stand verisi yüklenemedi.");
      }
    } catch (e) {
      print("Error in virtual stand API request: $e");
    }

    print("getData fonksiyonu başarıyla tamamlandı");
  }

  bool isPusherConnected = false;
  Set<String> subscribedChannels = {};

  Future<void> _subscribeToPusher() async {
    print('Starting subscription process to Pusher channel...');

    if (meeting == null || participant == null) {
      print('Error: Meeting or Participant is null. Cannot subscribe to Pusher.');
      return;
    }

    String channelName = 'meeting-${meeting!.id}-${participant!.type}';
    print('Channel name constructed: $channelName');

    PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

    if (!isPusherConnected) {
      print('Pusher is not connected, attempting to connect...');
      try {
        await pusher.init(apiKey: "314fc649c9f65b8d7960", cluster: "eu");
        await pusher.connect();

        isPusherConnected = true;
        print('Pusher connected successfully.');
      } catch (e) {
        print('Error connecting to Pusher: $e');
        return;
      }
    } else {
      print('Pusher is already connected.');
    }

    if (subscribedChannels.contains(channelName)) {
      print('Already subscribed to channel: $channelName.');
      return;
    }

    print('Subscribing to channel: $channelName');
    try {
      await pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          print('Event received on channel: $channelName');
          print('Event data: ${event.data}');

          if (event.data.isNotEmpty) {
            try {
              print('Parsing event data...');
              final data = jsonDecode(event.data);

              if (data.containsKey('hall_id')) {
                int hallId = data['hall_id'];
                print('hall_id found: $hallId');  // Burada hallId yazdırılıyor

                // Mevcut hall_id ile karşılaştırma
                if (hallId == meeting!.sessionFirstHallId) {
                  print('Correct Hall ID: $hallId');
                } else {
                  print('Incorrect Hall ID: $hallId');
                }

                // 'keypad-activated' event'ini işleme
                if (event.eventName == 'keypad-activated') {
                  print('Keypad activated event received. Navigating to KeypadView...');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => KeypadView(hallId: hallId)),
                  );
                }

                // **Debate eventlerini işleme**
                if (event.eventName == 'debate' || event.eventName == 'debate-activated') {
                  print('${event.eventName} event received. Checking hall_id...');
                  if (hallId == meeting!.sessionFirstHallId) {
                    print('hall_id matched! Navigating to DebateView...');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DebateView(hallId: hallId)),
                    );
                  } else {
                    print('Incorrect Hall ID for debate: $hallId');
                  }
                }

              } else {
                print('Error: hall_id not found in event data.');
              }
            } catch (e) {
              print('Error parsing event data: $e');
            }
          } else {
            print('No data received in Pusher event.');
          }
        },
      );

      subscribedChannels.add(channelName);
      print('Successfully subscribed to Pusher channel: $channelName');
    } catch (e) {
      print('Error during subscription to channel: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getData();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (meeting != null && meeting!.sessionFirstHallId != null) {
        bool hasKeypad = await checkForKeypad(meeting!.sessionFirstHallId!);
        if (hasKeypad) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    KeypadView(hallId: meeting!.sessionFirstHallId!)),
          );
        }
      }
    });
  }
  Future<void> _connectToPusher() async {
    if (isPusherConnected) {
      print('Pusher is already connected');
      return;
    }
    pusher = PusherChannelsFlutter.getInstance();
    await pusher?.init(apiKey: "314fc649c9f65b8d7960", cluster: "eu");
    await pusher?.connect();
    isPusherConnected = true;
    print("Pusher connected successfully.");

    await pusher?.subscribe(channelName: 'meeting-1-attendee', onEvent: _handlePusherEvent);
  }

  void _handlePusherEvent(PusherEvent event) {
    print('Event received on channel: meeting-1-attendee');
    print('Event Name: ${event.eventName}');
    print('Event Data: ${event.data}');

    // Event'in debate ya da debate-activated olmasına dikkat edin
    if (event.eventName == 'debate' || event.eventName == 'debate-activated') {
      print('Debate event triggered');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DebateView(hallId: 1)),
      );
    } else {
      print('Unhandled event type: ${event.eventName}');
    }
  }
 /*   Degisek@override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);  // Lifecycle gözlemleyiciyi kaldırıyoruz
    super.dispose();
  } */
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka planda ya da öndeyken Pusher bağlantısını yönetiyoruz
    if (state == AppLifecycleState.resumed) {
      print("App resumed - reconnecting to Pusher");
      _connectToPusher(); // Eğer uygulama aktif olursa Pusher'a tekrar bağlanıyoruz
    } else if (state == AppLifecycleState.paused) {
      print("App paused - you can handle Pusher disconnection if needed");
      // Uygulama arka planda kalırken isterseniz Pusher bağlantısını kapatabilirsiniz.
      // await pusher?.disconnect();
    }
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
          ))
          : Column(children: [
        Image.network(
          meeting != null &&
              meeting?.bannerName != null &&
              meeting?.bannerExtension != null
              ? "https://app.kongrepad.com/storage/meeting-banners/${meeting!.bannerName}.${meeting!.bannerExtension}"
              : "",
        ),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
                child: LowerHalfEllipse(screenWidth, screenHeight * 0.07)),
            Column(
              children: [
                SizedBox(
                  height: screenHeight * 0.01,
                ),
                Text(
                  "${participant?.fullName}",
                  style:
                  const TextStyle(fontSize: 25, color: Colors.white),
                )
              ],
            ),
          ],
        ),
        SizedBox(
          height: screenHeight * 0.04,
        ),
        Container(
          width: screenWidth * 0.95,
          height: screenHeight * 0.002,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icon/chevron.left.svg',
              color: Colors.white,
              height: screenHeight * 0.02,
            ),
            SizedBox(
              width: screenWidth * 0.8,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  height: screenHeight * 0.07,
                  child: Row(
                    children: virtualStands?.map((stand) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VirtualStandView(stand: stand),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Image.network(
                                'https://app.kongrepad.com/storage/virtual-stands/${stand.fileName}.${stand.fileExtension}',
                                fit: BoxFit.contain,
                              ),
                            )

                        ),
                      );
                    }).toList() ??
                        [],
                  ),
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icon/chevron.right.svg',
              color: Colors.white,
              height: screenHeight * 0.02,
            ),
          ],
        ),
        Container(
          width: screenWidth * 0.95,
          height: screenHeight * 0.002,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(
          height: screenHeight * 0.04,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: screenWidth * 0.45,
              height: screenHeight * 0.16,
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        AppConstants.buttonLightPurple),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape:
                    MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (meeting?.sessionHallCount == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SessionView(
                                hallId: meeting!.sessionFirstHallId!)),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppConstants.backgroundBlue,
                            contentPadding: EdgeInsets.zero,
                            content: SizedBox(
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.8,
                              child: const HallsView(type: "session"),
                            ),
                          );
                        },
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icon/play.fill.svg',
                        color: Colors.white,
                        height: screenHeight * 0.06,
                      ),
                      const Text(
                        'Sunum izle',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  )),
            ),
            SizedBox(
              width: screenWidth * 0.01,
            ),
            SizedBox(
              width: screenWidth * 0.45,
              height: screenHeight * 0.16,
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.redAccent),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape:
                    MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (participant?.type! != "attendee") {
                      AlertService().showAlertDialog(
                        context,
                        title: 'Uyarı',
                        content: 'Soru sorma izniniz yok!',
                      );
                    } else if (meeting?.questionHallCount == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AskQuestionView(
                                hallId: meeting!.questionFirstHallId!)),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppConstants.backgroundBlue,
                            contentPadding: EdgeInsets.zero,
                            content: SizedBox(
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.8,
                              child: const HallsView(type: "question"),
                            ),
                          );
                        },
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icon/questionmark.svg',
                        color: Colors.white,
                        height: screenHeight * 0.06,
                      ),
                      const Text(
                        'Soru Sor',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  )),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: screenWidth * 0.45,
              height: screenHeight * 0.16,
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        AppConstants.buttonYellow),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape:
                    MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (meeting?.programHallCount == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProgramDaysView(
                                hallId: meeting!.programFirstHallId!)),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppConstants.backgroundBlue,
                            contentPadding: EdgeInsets.zero,
                            content: SizedBox(
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.8,
                              child: const HallsView(type: "program"),
                            ),
                          );
                        },
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icon/book.fill.svg',
                        color: Colors.white,
                        height: screenHeight * 0.06,
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      const Text(
                        'Bilimsel Program',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  )),
            ),
            SizedBox(
              width: screenWidth * 0.01,
            ),
            SizedBox(
              width: screenWidth * 0.45,
              height: screenHeight * 0.16,
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all<Color>(AppConstants.buttonLightBlue),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape:
                    MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (participant?.type! != "attendee") {
                      AlertService().showAlertDialog(
                        context,
                        title: 'Uyarı',
                        content: 'Mail gönderme izniniz yok!',
                      );
                    } else if (meeting?.mailHallCount == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProgramDaysForMailView(
                                hallId: meeting!.mailFirstHallId!)),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppConstants.backgroundBlue,
                            contentPadding: EdgeInsets.zero,
                            content: SizedBox(
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.8,
                              child: const HallsView(type: "mail"),
                            ),
                          );
                        },
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icon/envelope.open.fill.svg',
                        color: Colors.white,
                        height: screenHeight * 0.06,
                      ),
                      const Text(
                        'Mail gönder',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  )),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: screenWidth * 0.45,
              height: screenHeight * 0.16,
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        AppConstants.buttonDarkBlue),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape:
                    MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SurveysView()),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icon/checklist.checked.svg',
                        color: Colors.white,
                        height: screenHeight * 0.06,
                      ),
                      const Text(
                        'Anketler',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  )),
            ),
            SizedBox(
              width: screenWidth * 0.01,
            ),
            SizedBox(
              width: screenWidth * 0.45,
              height: screenHeight * 0.16,
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        AppConstants.buttonGreen),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    shape:
                    MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ScoreGameView()),
                    );
                  },
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Icon(
                          FontAwesomeIcons.qrcode,  // QR kod ikonu
                          size: 60,                 // İkon boyutu
                          color: Colors.white,       // İkon rengi
                        ),
                      ),
                      const Text(
                        'QR okut',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  )),
            ),
          ],
        ),
        Spacer(),
        Container(
          width: screenWidth * 0.95,
          height: screenHeight * 0.001,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  logOut();
                  if (participant?.type! != "attendee") {
                    AlertService().showAlertDialog(
                      context,
                      title: 'Başarılı',
                      content: "Başarıyla çıkış yaptınız!",
                    );
                  }
                  Navigator.pop(context);
                },
                child: SvgPicture.asset(
                  'assets/icon/power.svg',
                  color: Colors.white,
                  height: screenHeight * 0.03,
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AnnouncementsView()),
                  );
                },
                child: SvgPicture.asset(
                  'assets/icon/bell.svg',
                  color: Colors.white,
                  height: screenHeight * 0.03,
                ),
              ),
              SizedBox(
                width: screenWidth * 0.01,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileView()),
                  );
                },
                child: SvgPicture.asset(
                  'assets/icon/person.svg',
                  color: Colors.white,
                  height: screenHeight * 0.03,
                ),
              ),
            ],
          ),
        ),
       /* ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DebateView(hallId: 1)),
              );
            },
            child: Text('data')) */
      ]),
    );
  }
}