import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kongrepad/AlertService.dart';
import 'package:kongrepad/AnnouncementsView.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:kongrepad/AskQuestionView.dart';
import 'package:kongrepad/HallsView.dart';
import 'package:kongrepad/LoginView.dart';
import 'package:kongrepad/ProfileView.dart';
import 'package:kongrepad/ProgramDaysForMailView.dart';
import 'package:kongrepad/ProgramDaysView.dart';
//import 'package:kongrepad/PusherService.dart';
import 'package:kongrepad/ScoreGameView.dart';
import 'package:kongrepad/SessionView.dart';
import 'package:kongrepad/SurveysView.dart';
import 'package:kongrepad/VirtualStandView.dart';
import 'package:kongrepad/Models/Meeting.dart';
import 'package:kongrepad/Models/Participant.dart';
import 'package:kongrepad/Models/VirtualStand.dart';
import 'package:pusher_beams/pusher_beams.dart';
//import 'package:pusher_channels_flutter/pusher-js/core/connection/protocol/message-types.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'KeypadView.dart';
import 'Models/Keypad.dart';

class LowerHalfEllipse extends StatelessWidget {
  final double width;
  final double height;

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

  const LowerHalfEllipse(this.width, this.height, {super.key});
}

class LowerHalfEllipsePainter extends CustomPainter {
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

class MainPageView extends StatefulWidget {
  const MainPageView({super.key, required this.title});

  final String title;

  @override
  State<MainPageView> createState() => _MainPageViewState();
}

class _MainPageViewState extends State<MainPageView> {
  Meeting? meeting;
  Participant? participant;
  List<VirtualStand>? virtualStands;
  bool _loading = true;

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
      final url = Uri.parse('http://app.kongrepad.com/api/v1/hall/$hallId/active-keypad');
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
    print("getData fonksiyonu başladı"); // Log başlatıldı

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') == null) {
      print("Token bulunamadı, LoginView'a yönlendiriliyor"); // Token kontrolü
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
      return;
    }

    final token = prefs.getString('token');
    print("Token bulundu: $token"); // Tokenin bulunduğu loglandı

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/meeting');
      print("Meeting verisi çekiliyor..."); // API isteği başlıyor
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print("Meeting API isteği tamamlandı. Status Code: ${response.statusCode}"); // Status code loglandı

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Meeting verisi başarıyla alındı: $jsonData"); // API yanıtı loglandı
        final meetingJson = MeetingJSON.fromJson(jsonData);

        setState(() {
          meeting = meetingJson.data;
        });

        if (meeting == null) {
          print("Meeting boş, LoginView'a yönlendiriliyor..."); // Eğer meeting boşsa log
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
          );
        } else {
          print("Meeting ID: ${meeting!.id}"); // Meeting id loglandı
        }
      } else {
        print("Meeting verisi yüklenemedi, LoginView'a yönlendiriliyor"); // Hata logu
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    } catch (e) {
      print("Error in meeting API request: $e"); // Hata loglandı
    }

    if (meeting != null && meeting!.id != null) {
      final meetingId = meeting!.id.toString();
      print("Pusher Beams abone olma işlemi başlıyor. Meeting ID: $meetingId"); // Abonelik işlemi başlıyor

      PusherBeams beamsClient = PusherBeams.instance;

      await beamsClient.clearDeviceInterests(); // Önceki interest'ler temizleniyor
      print("Pusher Beams önceki interest'ler temizlendi.");

      await beamsClient.addDeviceInterest('debug-meeting_$meetingId');
      print("Pusher Beams yeni interest eklendi: debug-meeting_$meetingId"); // Yeni interest eklendi loglandı
    }

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/participant');
      print("Participant verisi çekiliyor..."); // API isteği başlıyor
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print("Participant API isteği tamamlandı. Status Code: ${response.statusCode}"); // Status code loglandı

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Participant verisi başarıyla alındı: $jsonData"); // API yanıtı loglandı
        final participantJson = ParticipantJSON.fromJson(jsonData);

        setState(() {
          participant = participantJson.data;
          subscribePusher("meeting-${meeting?.id}-${participant?.type}");
        });
      } else {
        print("Participant verisi yüklenemedi, LoginView'a yönlendiriliyor"); // Hata logu
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    } catch (e) {
      print("Error in participant API request: $e"); // Hata loglandı
    }

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/virtual-stand');
      print("Virtual stand verisi çekiliyor..."); // API isteği başlıyor
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print("Virtual stand API isteği tamamlandı. Status Code: ${response.statusCode}"); // Status code loglandı

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Virtual stand verisi başarıyla alındı: $jsonData"); // API yanıtı loglandı
        final virtualStandsJson = VirtualStandsJSON.fromJson(jsonData);

        setState(() {
          virtualStands = virtualStandsJson.data;
          _loading = false;
        });
      } else {
        print("Virtual stand verisi yüklenemedi."); // Hata logu
      }
    } catch (e) {
      print("Error in virtual stand API request: $e"); // Hata loglandı
    }

    print("getData fonksiyonu başarıyla tamamlandı"); // Tüm işlem bitti
  }


  Future<void> subscribePusher(String channel) async {
    PusherService pusherService = PusherService();
    await pusherService.subscribeToChannel(channel);
  }



  @override
  void initState() {
    super.initState();


    _subscribeToPusher();
    // Fetch initial data for the meeting, participant, and virtual stands
    getData();

    // Subscribe to Pusher for live keypad updates
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _subscribeToPusher();  // Set up real-time monitoring
    });

    // After getting meeting details, check if there's an active keypad
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (meeting != null && meeting!.sessionFirstHallId != null) {
        bool hasKeypad = await checkForKeypad(meeting!.sessionFirstHallId!);
        if (hasKeypad) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KeypadView(hallId: meeting!.sessionFirstHallId!)),
          );
        }
      }
    });
  }

// Pusher subscription logic
  Future<void> _subscribeToPusher() async {
    PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
    await pusher.init(apiKey: "314fc649c9f65b8d7960", cluster: "eu");
    await pusher.connect();

    // Subscribe to the channel for keypad updates
    pusher.subscribe(
      channelName: 'keypad-updates',
      onEvent: (event) {
        print('Keypad event received: ${event.data}');

        // Here, you can parse the event data and check if a keypad became active
        if (event.eventName == 'keypad-activated') {
          // Example logic: Navigate to KeypadView if a keypad was activated
          int hallId = int.parse(event.data['hall_id']);  // Extract hallId from event
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KeypadView(hallId: hallId),
            ),
          );
        }
      },
    );

    print('Subscribed to Pusher for live keypad updates');
  }



  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Column(children: [
          Image.network(meeting != null &&
              meeting?.bannerName != null &&
              meeting?.bannerExtension != null
              ? "https://app.kongrepad.com/storage/meeting-banners/${meeting!.bannerName}.${meeting!.bannerExtension}"
              : ""),
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
                    style: const TextStyle(fontSize: 25, color: Colors.white),
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
                            child: Image.network(
                              'https://app.kongrepad.com/storage/virtual-stands/${stand.fileName}.${stand.fileExtension}',
                              // Adjust image width as needed
                              height: screenHeight * 0.04,
                              // Adjust image height as needed
                              fit: BoxFit.contain,
                            ),
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
          //BURAYA BAK
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             /*ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KeypadView(hallId: 1), // Replace with appropriate hallId
                    ),
                  );
                },
                child: const Text('Go to Keypad'),
              ),
    */
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
                width: screenWidth*0.01,
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
                width: screenWidth*0.01,
              ),
              SizedBox(
                width: screenWidth * 0.45,
                height: screenHeight * 0.16,
                child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          AppConstants.buttonLightBlue),
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
                width: screenWidth*0.01,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icon/leaf.fill.svg',
                          color: Colors.white,
                          height: screenHeight * 0.06,
                        ),
                        const Text(
                          'Doğaya Can Ver',
                          style: TextStyle(fontSize: 18),
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
                  width: screenWidth*0.01,
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
          )
        ]),
      ),
    );
  }
}
