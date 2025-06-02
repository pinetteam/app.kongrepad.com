import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:pusher_beams/pusher_beams.dart';
import '../../services/auth_service.dart';
import '../../services/pusher_service.dart';
import '../../services/alert_service.dart';
import '../../utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'AnnouncementsView.dart';
import 'AskQuestionView.dart';
import 'HallsView.dart';
import '../Models/VirtualStand.dart';
import '../../models/meeting.dart';
import '../../models/participant.dart';
import 'LoginView.dart';
import 'ProfileView.dart';
import 'ProgramDaysForMailView.dart';
import 'ProgramDaysView.dart';
import 'ScoreGameView.dart';
import 'SessionView.dart';
import 'SurveysView.dart';
import 'VirtualStandView.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/notification_helper.dart';
import 'lower_half_ellipse.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MainPageView extends StatefulWidget {
  const MainPageView({super.key, required this.title});

  final String title;

  @override
  State<MainPageView> createState() => _MainPageViewState();
}

class _MainPageViewState extends State<MainPageView>
    with WidgetsBindingObserver {
  Meeting? meeting;
  Participant? participant;
  List<VirtualStand>? virtualStands;
  bool _loading = true;

  // Fetch the FCM token
  Future<String?> getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print("FCM Token: $token"); // Token'ı konsola yazdırma
    return token;
  }

  Future<void> setupPusherBeams(
      Meeting meeting, Participant participant) async {
    PusherBeams beamsClient = PusherBeams.instance;

    // Start Pusher Beams with Instance ID
    await beamsClient.start(
        '8b5ebe3c-8106-454b-b4c7-b7c10a9320cf'); // Pusher Beams Instance ID

    // Dinamik interest oluştur
    if (meeting.id != null &&
        participant.type != null &&
        participant.id != null) {
      String interest =
          'meeting-${meeting.id}-${participant.type}-${participant.id}';
      await beamsClient.addDeviceInterest(interest);
      print("Added dynamic interest: $interest");
    } else {
      print("Meeting or Participant data is missing, cannot create interest.");
    }

    // Get FCM token
    String? token = await getFCMToken();
    if (token != null) {
      print("FCM Token received: $token");
    }
  }

  void _subscribeToPusher() async {
    if (meeting != null && participant != null) {
      PusherService pusherService = PusherService();
      await pusherService.subscribeToPusher(meeting!.id!, context);
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
    checkNotificationPermission(context); // Bildirim izinlerini kontrol eder.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (meeting?.id != null) {
        print("Resuming app, re-subscribing to Pusher.");
        PusherService().subscribeToPusher(meeting!.id!, context);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PusherService().disconnectPusher();
    super.dispose();
  }

  Future<void> getData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Token kontrolü
      String? token = prefs.getString('token');
      if (token == null) {
        print("Token bulunamadı, LoginView'e yönlendiriliyor.");
        _redirectToLogin();
        return;
      }

      print("Mevcut token: $token");

      // Meeting ve Participant bilgilerini çek
      print("Meeting ve participant bilgileri alınıyor...");

      meeting = await AuthService().getMeeting();
      participant = await AuthService().getParticipant();

      // Meeting kontrolü
      if (meeting == null) {
        print("Meeting bilgisi alınamadı, LoginView'e yönlendiriliyor.");
        _redirectToLogin();
        return;
      }

      // Participant kontrolü
      if (participant == null) {
        print("Participant bilgisi alınamadı, LoginView'e yönlendiriliyor.");
        _redirectToLogin();
        return;
      }

      print("Meeting ID: ${meeting!.id}");
      print("Participant ID: ${participant!.id}, Type: ${participant!.type}");

      // Virtual stands verilerini çek (hata olsa bile devam et)
      try {
        virtualStands = await AuthService().getVirtualStands();
        print("Virtual stands yüklendi: ${virtualStands?.length ?? 0} adet");
      } catch (e) {
        print("Virtual stands yüklenemedi: $e");
        virtualStands = [];
      }

      // Participant ID kaydet
      if (participant!.id != null) {
        await AuthService().saveParticipantId(participant!.id!);
        print("Participant ID kaydedildi: ${participant!.id}");
      }

      // Pusher Beams ayarla
      try {
        await setupPusherBeams(meeting!, participant!);
        print("Pusher Beams kurulumu tamamlandı");
      } catch (e) {
        print("Pusher Beams kurulum hatası: $e");
      }

      // Pusher'a abone ol
      try {
        await PusherService().subscribeToPusher(meeting!.id!, context);
        print("Pusher aboneliği başarılı");
      } catch (e) {
        print("Pusher abonelik hatası: $e");
      }

      print("getData başarıyla tamamlandı");

    } catch (e) {
      print("getData genel hatası: $e");
      _redirectToLogin();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
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
                          style: const TextStyle(
                              fontSize: 25, color: Colors.white),
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
                                                          VirtualStandView(
                                                              stand: stand),
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child: Image.network(
                                                    'https://app.kongrepad.com/storage/virtual-stands/${stand.fileName}.${stand.fileExtension}',
                                                    fit: BoxFit.contain,
                                                  ),
                                                )),
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
                                    backgroundColor:
                                        WidgetStateProperty.all<Color>(
                                            AppConstants.buttonLightPurple),
                                    foregroundColor:
                                        WidgetStateProperty.all<Color>(
                                            Colors.white),
                                    padding: WidgetStateProperty.all<
                                        EdgeInsetsGeometry>(
                                      const EdgeInsets.all(12),
                                    ),
                                    shape: WidgetStateProperty.all<
                                        RoundedRectangleBorder>(
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
                                                hallId: meeting!
                                                    .sessionFirstHallId!)),
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor:
                                                AppConstants.backgroundBlue,
                                            contentPadding: EdgeInsets.zero,
                                            content: SizedBox(
                                              width: screenWidth * 0.9,
                                              height: screenHeight * 0.8,
                                              child: const HallsView(
                                                  type: "session"),
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
                                      Text(
                                        AppLocalizations.of(context)
                                            .translate('watch_presentation'),
                                        style: TextStyle(fontSize: 18),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
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
                                        WidgetStateProperty.all<Color>(
                                            Colors.redAccent),
                                    foregroundColor:
                                        WidgetStateProperty.all<Color>(
                                            Colors.white),
                                    padding: WidgetStateProperty.all<
                                        EdgeInsetsGeometry>(
                                      const EdgeInsets.all(12),
                                    ),
                                    shape: WidgetStateProperty.all<
                                        RoundedRectangleBorder>(
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
                                    } else if (meeting?.questionHallCount ==
                                        1) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AskQuestionView(
                                                    hallId: meeting!
                                                        .questionFirstHallId!)),
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor:
                                                AppConstants.backgroundBlue,
                                            contentPadding: EdgeInsets.zero,
                                            content: SizedBox(
                                              width: screenWidth * 0.9,
                                              height: screenHeight * 0.8,
                                              child: const HallsView(
                                                  type: "question"),
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
                                      Text(
                                        AppLocalizations.of(context)
                                            .translate('ask_question'),
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
                            backgroundColor: WidgetStateProperty.all<Color>(
                                AppConstants.buttonYellow),
                            foregroundColor:
                                WidgetStateProperty.all<Color>(Colors.white),
                            padding:
                                WidgetStateProperty.all<EdgeInsetsGeometry>(
                              const EdgeInsets.all(12),
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
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
                                    backgroundColor:
                                        AppConstants.backgroundBlue,
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
                              Text(
                                AppLocalizations.of(context)
                                    .translate('scientific_program'),
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
                            backgroundColor: WidgetStateProperty.all<Color>(
                                AppConstants.buttonLightBlue),
                            foregroundColor:
                                WidgetStateProperty.all<Color>(Colors.white),
                            padding:
                                WidgetStateProperty.all<EdgeInsetsGeometry>(
                              const EdgeInsets.all(12),
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          onPressed: () {
                            if (participant?.type! != "attendee") {
                              AlertService().showAlertDialog(
                                context,
                                title: AppLocalizations.of(context)
                                    .translate('warning'),
                                content: AppLocalizations.of(context)
                                    .translate('no_permission_mail'),
                              );
                            } else if (meeting?.mailHallCount == 1) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ProgramDaysForMailView(
                                            hallId: meeting!.mailFirstHallId!)),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor:
                                        AppConstants.backgroundBlue,
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
                              Text(
                                AppLocalizations.of(context)
                                    .translate('send_mail'),
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
                            backgroundColor: WidgetStateProperty.all<Color>(
                                AppConstants.buttonDarkBlue),
                            foregroundColor:
                                WidgetStateProperty.all<Color>(Colors.white),
                            padding:
                                WidgetStateProperty.all<EdgeInsetsGeometry>(
                              const EdgeInsets.all(12),
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
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
                              Text(
                                AppLocalizations.of(context)
                                    .translate('surveys'),
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
                            backgroundColor: WidgetStateProperty.all<Color>(
                                AppConstants.buttonGreen),
                            foregroundColor:
                                WidgetStateProperty.all<Color>(Colors.white),
                            padding:
                                WidgetStateProperty.all<EdgeInsetsGeometry>(
                              const EdgeInsets.all(12),
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
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
                              Center(
                                child: Icon(
                                  FontAwesomeIcons.qrcode,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)
                                    .translate('scan_qr'),
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
                              title: AppLocalizations.of(context)
                                  .translate('success'),
                              content: AppLocalizations.of(context)
                                  .translate('logout_success'),
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
                                builder: (context) =>
                                    const AnnouncementsView()),
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
