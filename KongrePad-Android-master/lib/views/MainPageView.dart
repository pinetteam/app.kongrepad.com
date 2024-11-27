import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kongrepad/views/LoginView.dart';
import 'package:kongrepad/views/lower_half_ellipse.dart';
import 'package:pusher_beams/pusher_beams.dart';
import '../../services/auth_service.dart';
import '../../services/pusher_service.dart';
import '../../services/alert_service.dart';
import '../../utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AnnouncementsView.dart';
import 'AskQuestionView.dart';
import 'HallsView.dart';
import '../Models/VirtualStand.dart';
import '../../models/meeting.dart';
import '../../models/participant.dart';
import 'ProfileView.dart';
import 'ProgramDaysForMailView.dart';
import 'ProgramDaysView.dart';
import 'ScoreGameView.dart';
import 'SessionView.dart';
import 'SurveysView.dart';
import 'VirtualStandView.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class MainPageView extends StatefulWidget {
  const MainPageView({super.key, required this.title});

  final String title;

  @override
  State<MainPageView> createState() => _MainPageViewState();
}

class _MainPageViewState extends State<MainPageView> with WidgetsBindingObserver {
  Meeting? meeting;
  Participant? participant;
  List<VirtualStand>? virtualStands;
  bool _loading = true;


  // Fetch the FCM token
  Future<String?> getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print("FCM Token: $token");  // Token'ı konsola yazdırma
    return token;
  }
  // Setup Pusher Beams and get FCM Token
  Future<void> setupPusherBeams() async {
    PusherBeams beamsClient = PusherBeams.instance;

    // Start Pusher Beams with Instance ID
    await beamsClient.start('8dedc4bd-d0d1-4d83-825f-071ab329a328');  // Pusher Beams Instance ID

    // Subscribe the device to an interest
  //  await beamsClient.addDeviceInterest('debug-meeting-3-attendee');

    // Get FCM token
    String? token = await getFCMToken();
    if (token != null) {
      print("FCM Token received: $token");
    }
  }
  void _subscribeToPusher() async {
    if (meeting != null && participant != null) {
      PusherService pusherService = PusherService();
      await pusherService.subscribeToPusher(meeting!.id!, participant!.type!, context);
    } else {
      print("Meeting or participant is null. Cannot subscribe to Pusher.");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getData();
    _subscribeToPusher();
    PusherBeams beamsClient = PusherBeams.instance;
    beamsClient.start('8b5ebe3c-8106-454b-b4c7-b7c10a9320cf');  // Pusher Beams Instance ID
    beamsClient.addDeviceInterest('meeting-3-attendee');

  }

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
      return;
    }

    // Verileri çeken servisleri kullanın
    meeting = await AuthService().getMeeting();
    participant = await AuthService().getParticipant();
    virtualStands = await AuthService().getVirtualStands();

    if (meeting == null || meeting!.id == null || participant == null || participant!.type == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    } else {
      // `id` ve `type` kesinlikle null değilse `subscribeToPusher` çağrısı yapılır
      await PusherService().subscribeToPusher(meeting!.id!, participant!.type.toString(), context);
      print(meeting?.id);
      print(participant?.type);
      print(participant?.id);
      print(meeting?.sessionFirstHallId);
      print(meeting?.mailFirstHallId);



    }


    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    return Scaffold(
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          Image.network(
            meeting != null
                ? "https://app.kongrepad.com/storage/meeting-banners/${meeting!.bannerName}.${meeting!.bannerExtension}"
                : "",
          ),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              LowerHalfEllipse(screenWidth, screenHeight * 0.07),
              Column(
                children: [
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "${participant?.fullName}",
                    style: const TextStyle(fontSize: 25, color: Colors.white),
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
                                  AppConstants.buttonLightPurple
                              ),
                              foregroundColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                              padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
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
                ],
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
                   // logOut();
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
        ],
      ),
    );
  }
}
