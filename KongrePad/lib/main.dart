import 'package:KongrePad/utils/app_constants.dart';
import 'package:KongrePad/views/AskQuestionView.dart';
import 'package:KongrePad/views/LoginView.dart';
import 'package:KongrePad/views/MainPageView.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pusher_beams/pusher_beams.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences instance'ını al
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print(" Firebase başarıyla başlatıldı!");
  } catch (e) {
    print(" Firebase başlatılamadı: $e");
    return;
  }

  try {
    PusherBeams beamsClient = PusherBeams.instance;
    await beamsClient.start('8b5ebe3c-8106-454b-b4c7-b7c10a9320cf');
    print("Pusher Beams başarıyla başlatıldı!");
  } catch (e) {
    print("Pusher Beams başlatılamadı: $e");
    // Uygulama Pusher olmadan da çalışabilir
  }

  // Dil kodunu kontrol et
  String? languageCode = prefs.getString('languageCode') ?? 'en';

  // Kullanıcı oturum durumunu kontrol et
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String? userToken = prefs.getString('userToken');

  runApp(MyApp(
    locale: Locale(languageCode),
    isLoggedIn: isLoggedIn,
    userToken: userToken,
  ));
}

class MyApp extends StatefulWidget {
  final Locale locale;
  final bool isLoggedIn;
  final String? userToken;

  const MyApp({
    Key? key,
    required this.locale,
    required this.isLoggedIn,
    this.userToken,
  }) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) async {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    if (state != null) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', newLocale.languageCode);
      state.setLocale(newLocale);
    }
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget initialRoute = widget.isLoggedIn && widget.userToken != null
        ? const MainPageView(title: '')
        : const LoginView();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('tr', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        scaffoldBackgroundColor: AppConstants.backgroundBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => const LoginView(),
        '/main': (context) => const MainPageView(title: ''),
      },
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/ask-question':
            final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AskQuestionView(
                hallId: args['hallId'], // Sadece hallId geçir
              ),
            );
          default:
            return null;
        }
      },
      home: initialRoute,
    );
  }
}