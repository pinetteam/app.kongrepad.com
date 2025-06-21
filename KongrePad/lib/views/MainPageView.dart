import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:pusher_beams/pusher_beams.dart';
import '../../services/auth_service.dart';
import '../../services/pusher_service.dart';
import '../../services/alert_service.dart';
import '../../services/banner_service.dart';
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
import 'session_view.dart';
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
  bool _sessionButtonLoading = false; // Session button için loading state
  String? _errorMessage;

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

  // MainPageView.dart - _initializeData metodunu bu ile değiştir:

  Future<void> _initializeData() async {
    if (_isInitialized || !mounted) return;

    try {
      setState(() => _loading = true);

      final authService = AuthService();

      // 1. ÖNCELİKLE LOGIN KONTROLÜ YAP
      print('MainPage - Login durumu kontrol ediliyor...');
      final isLoggedIn = await authService.isLoggedIn();

      if (!isLoggedIn) {
        print(
            'MainPage - Kullanıcı giriş yapmamış, LoginView\'e yönlendiriliyor');
        _redirectToLogin();
        return;
      }

      print('MainPage - Kullanıcı giriş yapmış, veriler yükleniyor...');

      // 2. STORED DATA'DAN YÜKLEMEYİ DENE
      final storedParticipant = await authService.getStoredParticipant();
      final storedMeeting = await authService.getStoredMeeting();

      if (storedParticipant != null && storedMeeting != null) {
        // Stored data'dan yükle
        print('MainPage - Stored data\'dan yükleniyor');
        participant = Participant.fromJson(storedParticipant);
        meeting = Meeting.fromJson(storedMeeting);

        print(
            'MainPage - ✅ Stored data loaded: ${participant?.fullName}, Meeting: ${meeting?.title}');
      } else {
        // Fresh data al
        print('MainPage - Fresh data alınıyor...');

        try {
          // Profil bilgilerini al
          final profileData = await authService.getProfile();
          if (profileData['participant'] == null) {
            print('MainPage - Profile participant data yok, logout');
            _redirectToLogin();
            return;
          }

          participant = Participant.fromJson(profileData['participant']);

          // Meeting bilgilerini al
          meeting = await authService.getMeeting();

          if (meeting == null || participant == null) {
            print('MainPage - Meeting/Participant alınamadı, logout');
            _redirectToLogin();
            return;
          }

          // Fresh data'yı kaydet
          await authService.saveLoginData(
            token: await authService.getStoredToken() ?? '',
            participant: profileData['participant'],
            meeting: meeting!.toJson(),
          );

          print('MainPage - ✅ Fresh data loaded and saved');
        } catch (e) {
          print('MainPage - Fresh data load error: $e');
          _redirectToLogin();
          return;
        }
      }

      if (!mounted) return;

      // 3. PUSHER VE DİĞER SERVİSLERİ BAŞLAT
      try {
        await setupPusherBeams(meeting!, participant!);
        _subscribeToPusher();
        print('MainPage - ✅ Pusher setup complete');
      } catch (e) {
        print('MainPage - Pusher setup error: $e');
        // Pusher hatası uygulamayı durdurmasın
      }

      // 4. VIRTUAL STANDS YÜKLEMEYİ DENE
      try {
        await _loadVirtualStands();
      } catch (e) {
        print('MainPage - Virtual stands error: $e');
        // Virtual stands hatası uygulamayı durdurmasın
        virtualStands = []; // Boş liste ata
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _loading = false;
        });

        print('MainPage - ✅ Initialization complete');
      }
    } catch (e) {
      print('MainPage - Initialization error: $e');
      if (mounted) {
        _redirectToLogin();
      }
    }
  }

// Virtual stands yükleme metodu ekle
  Future<void> _loadVirtualStands() async {
    try {
      // Virtual stands API call
      final authService = AuthService();
      final token = await authService.getStoredToken();

      if (token != null && meeting?.id != null) {
        final response = await http.get(
          Uri.parse(
              'https://api.kongrepad.com/api/v1/meetings/${meeting!.id}/virtual-stands'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['data'] != null) {
            final standsList = data['data'] as List;
            virtualStands = standsList
                .map((stand) => VirtualStand.fromJson(stand))
                .toList();
            print('MainPage - ${virtualStands?.length} virtual stand yüklendi');

            if (mounted) setState(() {});
          }
        }
      }
    } catch (e) {
      print('MainPage - Virtual stands load error: $e');
      virtualStands = []; // Boş liste ata
    }
  }

// _redirectToLogin metodunu güncelle
  void _redirectToLogin() async {
    print('MainPage - Logout işlemi başlatılıyor...');

    try {
      // Auth service ile temizlik yap
      final authService = AuthService();
      await authService.clearStorage();

      // Pusher bağlantısını kes
      PusherService().disconnectPusher();

      print('MainPage - ✅ Logout complete');
    } catch (e) {
      print('MainPage - Logout error: $e');
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false, // Tüm önceki route'ları temizle
      );
    }
  }

// _checkLoginStatus metodunu da güncelle (initState'te çağrılıyor)
  Future<void> _checkLoginStatus() async {
    // Bu metod artık gerekli değil, _initializeData() her şeyi hallediyor
    // Ama varsa şunu yap:

    final authService = AuthService();
    final hasStoredData = await authService.hasValidStoredData();

    if (hasStoredData) {
      // Stored data var, normal initialization'a devam et
      return;
    } else {
      // Stored data yok, direkt login'e yönlendir
      _redirectToLogin();
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

  Widget _buildBannerImage() {
    // BannerService error state kontrolü
    if (BannerService().isInErrorState || meeting?.id == null) {
      return _buildDefaultBanner();
    }

    return FutureBuilder<http.Response?>(
      future: BannerService().loadBanner(meeting!.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildDefaultBanner();
        }

        final response = snapshot.data!;
        if (response.statusCode != 200) {
          return _buildDefaultBanner();
        }

        // Başarılı banner response'u
        return Image.memory(
          response.bodyBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          cacheWidth: 800,
          cacheHeight: 400,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultBanner();
          },
        );
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
                                    isLoading: _sessionButtonLoading,
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
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isLoading ? color.withOpacity(0.7) : color,
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
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  )
                else if (isIconAsset)
                  SvgPicture.asset(
                    icon,
                    color: Colors.white,
                    height: 48,
                  )
                else
                  const Icon(
                    FontAwesomeIcons.qrcode,
                    size: 48,
                    color: Colors.white,
                  ),
                const SizedBox(height: 12),
                Text(
                  isLoading ? 'Yükleniyor...' : label,
                  style: const TextStyle(
                    fontSize: 16,
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

  void _handleSessionButton() async {
    // Eğer zaten loading ise, tekrar çalıştırma
    if (_sessionButtonLoading) {
      print('MainPage - Session button zaten çalışıyor, işlem engellendi');
      return;
    }

    setState(() {
      _sessionButtonLoading = true;
    });

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

        if (currentActivities != null &&
            currentActivities['live_sessions'] != null) {
          // ✅ YENİ: Map ve List formatını destekle
          final liveSessionsData = currentActivities['live_sessions'];
          List liveSessions;

          if (liveSessionsData is Map) {
            // Map formatından List'e çevir
            liveSessions = liveSessionsData.values.toList();
            print(
                'MainPage - Live sessions Map formatında, ${liveSessions.length} session bulundu');
          } else if (liveSessionsData is List) {
            // Zaten List formatında
            liveSessions = liveSessionsData;
            print(
                'MainPage - Live sessions List formatında, ${liveSessions.length} session bulundu');
          } else {
            // Bilinmeyen format
            print(
                'MainPage - Live sessions bilinmeyen format: ${liveSessionsData.runtimeType}');
            liveSessions = [];
          }

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

            print(
                'MainPage - Tek session var, direkt açılıyor: Session $sessionId, Hall $hallId');

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
            print(
                'MainPage - Tüm session\'lar Hall $hallId\'de, direkt açılıyor');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionView(hallId: hallId),
              ),
            );
          } else {
            // Farklı hall'larda session'lar var → Hall listesi göster
            print(
                'MainPage - Farklı hall\'larda session\'lar var, liste gösteriliyor');

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
    } finally {
      // Loading state'i temizle
      if (mounted) {
        setState(() {
          _sessionButtonLoading = false;
        });
      }
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
    print('MainPage - Program button tıklandı');
    print(
        'MainPage - Meeting program hall count: ${meeting?.programHallCount}');
    print(
        'MainPage - Meeting program first hall id: ${meeting?.programFirstHallId}');

    if (participant?.type != "attendee") {
      print('MainPage - Kullanıcı attendee değil: ${participant?.type}');
      AlertService().showAlertDialog(
        context,
        title: AppLocalizations.of(context).translate('warning'),
        content:
            AppLocalizations.of(context).translate('no_permission_program'),
      );
      return;
    }

    // Program hall count kontrolü
    if (meeting?.programHallCount == null || meeting?.programHallCount == 0) {
      print('MainPage - Program hall count null veya 0, direkt halls göster');
      // Hall count bilgisi yoksa direkt HallsView göster
      _showProgramHallsDialog();
      return;
    }

    if (meeting!.programHallCount == 1 && meeting?.programFirstHallId != null) {
      print('MainPage - Tek program hall var: ${meeting!.programFirstHallId}');
      // Tek hall varsa direkt ProgramDaysView'a git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProgramDaysView(hallId: meeting!.programFirstHallId!),
        ),
      );
    } else {
      print('MainPage - Çoklu program hall var, HallsView göster');
      // Çoklu hall varsa HallsView göster
      _showProgramHallsDialog();
    }
  }

  void _showProgramHallsDialog() {
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
