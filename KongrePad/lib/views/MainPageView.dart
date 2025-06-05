import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:pusher_beams/pusher_beams.dart';
import '../../services/auth_service.dart';
import '../../services/pusher_service.dart';
import '../../services/alert_service.dart';
import '../../utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/session_service.dart';
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
  bool _isInitialized = false;

  // Fetch the FCM token
  Future<String?> getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print("FCM Token: $token"); // Token'ı konsola yazdırma
    return token;
  }

  Future<void> setupPusherBeams(
      Meeting meeting, Participant participant) async {
    if (!mounted) return;

    try {
      print(
          "Setting up Pusher Beams for Meeting ID: ${meeting.id}, Participant ID: ${participant.id}");

      final PusherBeams beamsClient = PusherBeams.instance;
      await beamsClient.start('8b5ebe3c-8106-454b-b4c7-b7c10a9320cf');

      // Interest oluştur
      String interest =
          'meeting-${meeting.id}-${participant.type}-${participant.id}';
      print("Adding interest: $interest");

      await beamsClient.addDeviceInterest(interest);
      print("Successfully added interest: $interest");

      // FCM token al
      String? token = await getFCMToken();
      if (token != null) {
        print("FCM Token received: $token");
      }
    } catch (e) {
      print("Error in setupPusherBeams: $e");
    }
  }

  void _subscribeToPusher() {
    if (meeting != null) {
      PusherService().subscribeToPusher(meeting!.id!, context);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
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

  Future<void> _initializeData() async {
    if (_isInitialized || !mounted) return;

    try {
      setState(() => _loading = true);

      final authService = AuthService();

      // Profil bilgilerini al
      final profileData = await authService.getProfile();
      participant = Participant.fromJson(profileData['participant']);

      // Meeting bilgilerini al
      meeting = await authService.getMeeting();

      if (meeting == null) {
        print("Meeting bilgisi alınamadı, LoginView'e yönlendiriliyor.");
        _redirectToLogin();
        return;
      }

      if (mounted) {
        // Pusher ayarlarını yap
        await setupPusherBeams(meeting!, participant!);
        _subscribeToPusher();

        setState(() {
          _isInitialized = true;
          _loading = false;
        });
      }
    } catch (e) {
      print("Initialization error: $e");
      if (mounted) {
        _redirectToLogin();
      }
    }
  }

  Future<void> _setupPusherChannels() async {
    try {
      if (meeting != null) {
        await PusherService().subscribeToPusher(meeting!.id!, context);
        print("Pusher aboneliği başarılı");
      }
    } catch (e) {
      print("Pusher abonelik hatası: $e");
    }
  }

  Future<void> _setupNotifications() async {
    try {
      String? fcmToken = await getFCMToken();
      print("FCM Token alındı: $fcmToken");
    } catch (e) {
      print("FCM Token alma hatası: $e");
    }
  }

  void _redirectToLogin() async {
    // Çıkış yaparken SharedPreferences'ı temizle
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Tüm verileri temizle

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  Widget _buildBannerImage() {
    return FutureBuilder<String?>(
      future: SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('token')),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildDefaultBanner();

        return meeting != null &&
                meeting!.bannerName != null &&
                meeting!.bannerExtension != null
            ? Image.network(
                "https://api.kongrepad.com/api/v1/meetings/${meeting!.id}/banner",
                headers: {
                  'Authorization': 'Bearer ${snapshot.data}',
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Banner yükleme hatası: $error');
                  return _buildDefaultBanner();
                },
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : _buildDefaultBanner();
      },
    );
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
          : SafeArea(
              child: Column(
                children: [
                  // Banner Section
                  SizedBox(
                    height: screenHeight * 0.2,
                    child: _buildBannerImage(),
                  ),

                  // Main Content Section
                  Expanded(
                    child: Column(
                      children: [
                        // User Info Section - Daha kompakt
                        Container(
                          color: AppConstants.backgroundBlue,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Text(
                                "${participant?.fullName}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                width: screenWidth * 0.95,
                                height: 1,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),

                        // Virtual Stands Section - Daha kompakt
                        SizedBox(
                          height: screenHeight * 0.08,
                          child: Row(
                            children: [
                              IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icon/chevron.left.svg',
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: virtualStands?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final stand = virtualStands![index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
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
                                        child: Image.network(
                                          'https://api.kongrepad.com/storage/virtual-stands/${stand.fileName}.${stand.fileExtension}',
                                          fit: BoxFit.contain,
                                          height: screenHeight * 0.06,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icon/chevron.right.svg',
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),

                        // Main Buttons Grid - Daha büyük ve profesyonel
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                _buildButtonRow(
                                  button1: _buildMainButton(
                                    icon: 'assets/icon/play.fill.svg',
                                    label: AppLocalizations.of(context)
                                        .translate('watch_presentation'),
                                    color: AppConstants.buttonLightPurple,
                                    onPressed: () => _handleSessionButton(),
                                  ),
                                  button2: _buildMainButton(
                                    icon: 'assets/icon/questionmark.svg',
                                    label: AppLocalizations.of(context)
                                        .translate('ask_question'),
                                    color: Colors.redAccent,
                                    onPressed: () => _handleQuestionButton(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildButtonRow(
                                  button1: _buildMainButton(
                                    icon: 'assets/icon/book.fill.svg',
                                    label: AppLocalizations.of(context)
                                        .translate('scientific_program'),
                                    color: AppConstants.buttonYellow,
                                    onPressed: () => _handleProgramButton(),
                                  ),
                                  button2: _buildMainButton(
                                    icon: 'assets/icon/envelope.open.fill.svg',
                                    label: AppLocalizations.of(context)
                                        .translate('send_mail'),
                                    color: AppConstants.buttonLightBlue,
                                    onPressed: () => _handleMailButton(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildButtonRow(
                                  button1: _buildMainButton(
                                    icon: 'assets/icon/checklist.checked.svg',
                                    label: AppLocalizations.of(context)
                                        .translate('surveys'),
                                    color: AppConstants.buttonDarkBlue,
                                    onPressed: () => _handleSurveysButton(),
                                  ),
                                  button2: _buildMainButton(
                                    icon: 'qr_code',
                                    label: AppLocalizations.of(context)
                                        .translate('scan_qr'),
                                    color: AppConstants.buttonGreen,
                                    onPressed: () => _handleQRButton(),
                                    isIconAsset: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Navigation - Daha kompakt
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icon/power.svg',
                                  color: Colors.white,
                                ),
                                onPressed: _redirectToLogin,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icon/bell.svg',
                                  color: Colors.white,
                                ),
                                onPressed: () => _handleAnnouncementsButton(),
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icon/person.svg',
                                  color: Colors.white,
                                ),
                                onPressed: () => _handleProfileButton(),
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
    );
  }

  Widget _buildButtonRow({required Widget button1, required Widget button2}) {
    return Expanded(
      child: Row(
        children: [
          Expanded(child: button1),
          const SizedBox(width: 12),
          Expanded(child: button2),
        ],
      ),
    );
  }

  Widget _buildMainButton({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isIconAsset = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isIconAsset)
                  SvgPicture.asset(
                    icon,
                    color: Colors.white,
                    height: 48, // Daha büyük ikon
                  )
                else
                  const Icon(
                    FontAwesomeIcons.qrcode,
                    size: 48, // Daha büyük ikon
                    color: Colors.white,
                  ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16, // Daha büyük yazı
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Button Handler Methods
// MainPageView.dart - _handleSessionButton metodunu bu ile değiştir:

  // MainPageView.dart - _handleSessionButton metodunu bu ile değiştir:

  void _handleSessionButton() async {
    try {
      print('MainPage - Session button tıklandı');

      // SessionService'i kullanarak aktif session'ları al
      final sessionService = SessionService();

      // Current meeting'den live sessions'ları al
      final authService = AuthService();
      final response = await http.get(
        Uri.parse('https://api.kongrepad.com/api/v1/meetings/current'),
        headers: {
          'Authorization': 'Bearer ${await authService.getStoredToken()}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final meetingData = jsonDecode(response.body);
        final currentActivities = meetingData['data']?['current_activities'];

        if (currentActivities != null && currentActivities['live_sessions'] != null) {
          final liveSessions = currentActivities['live_sessions'] as List;

          print('MainPage - ${liveSessions.length} aktif session bulundu');

          if (liveSessions.isEmpty) {
            // Hiç aktif session yok
            _showNoActiveSessionDialog();
            return;
          }

          if (liveSessions.length == 1) {
            // TEK SESSION VAR → DİREKT AÇ
            final session = liveSessions.first;
            final sessionId = session['id'];
            final hallId = session['program']?['hall_id'] ?? sessionId;

            print('MainPage - Tek session var, direkt açılıyor: Session $sessionId, Hall $hallId');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionView(hallId: hallId),
              ),
            );
            return;
          }

          // ÇOKLU SESSION VAR → Aktif hall'ları belirle
          print('MainPage - Çoklu session var');

          final activeHalls = <int>{};
          for (var session in liveSessions) {
            final hallId = session['program']?['hall_id'];
            if (hallId != null) activeHalls.add(hallId);
          }

          print('MainPage - Aktif hall\'lar: $activeHalls');

          if (activeHalls.length == 1) {
            // Tüm session'lar aynı hall'da → Direkt aç
            final hallId = activeHalls.first;
            print('MainPage - Tüm session\'lar Hall $hallId\'de, direkt açılıyor');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionView(hallId: hallId),
              ),
            );
          } else {
            // Farklı hall'larda session'lar var → Hall listesi göster
            print('MainPage - Farklı hall\'larda session\'lar var, liste gösteriliyor');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  backgroundColor: AppConstants.backgroundBlue,
                  body: HallsView(
                    type: "session",
                    meetingId: meeting!.id!,
                  ),
                ),
              ),
            );
          }
        } else {
          // Hiç current activities yok
          print('MainPage - Current activities bulunamadı');
          _showNoActiveSessionDialog();
        }
      } else {
        print('MainPage - Meeting current API failed: ${response.statusCode}');
        _showErrorDialog('Meeting bilgileri alınamadı');
      }
    } catch (e) {
      print('MainPage - Session button error: $e');
      _showErrorDialog('Oturum bilgileri alınamadı: $e');
    }
  }

  void _showNoActiveSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Aktif Oturum Yok',
          style: TextStyle(
            color: AppConstants.backgroundBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Şu anda hiçbir hall\'da aktif oturum bulunmuyor.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: TextStyle(color: AppConstants.backgroundBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Hata',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: TextStyle(color: AppConstants.backgroundBlue),
            ),
          ),
        ],
      ),
    );
  }





  void _handleQuestionButton() {
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
          builder: (context) =>
              AskQuestionView(hallId: meeting!.questionFirstHallId!),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppConstants.backgroundBlue,
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: HallsView(
                type: "question",
                meetingId: meeting!.id!,
              ),
            ),
          );
        },
      );
    }
  }

  void _handleProgramButton() {
    if (meeting?.programHallCount == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProgramDaysView(hallId: meeting!.programFirstHallId!),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppConstants.backgroundBlue,
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: HallsView(
                type: "program",
                meetingId: meeting!.id!,
              ),
            ),
          );
        },
      );
    }
  }

  void _handleMailButton() {
    if (participant?.type! != "attendee") {
      AlertService().showAlertDialog(
        context,
        title: AppLocalizations.of(context).translate('warning'),
        content: AppLocalizations.of(context).translate('no_permission_mail'),
      );
    } else if (meeting?.mailHallCount == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProgramDaysForMailView(hallId: meeting!.mailFirstHallId!),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppConstants.backgroundBlue,
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: HallsView(
                type: "mail",
                meetingId: meeting!.id!,
              ),
            ),
          );
        },
      );
    }
  }

  void _handleSurveysButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SurveysView(),
      ),
    );
  }

  void _handleQRButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScoreGameView(),
      ),
    );
  }

  void _handleAnnouncementsButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnnouncementsView(),
      ),
    );
  }

  void _handleProfileButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileView(),
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 200,
      color: AppConstants.backgroundBlue,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_icon.png',
              height: 80,
            ),
            const SizedBox(height: 10),
            Text(
              meeting?.title ?? 'Kongre',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
