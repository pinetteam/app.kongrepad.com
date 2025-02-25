import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kongrepad/utils/app_constants.dart';
import 'package:kongrepad/views/LoginView.dart';
import 'package:kongrepad/views/MainPageView.dart';
import 'package:pusher_beams/pusher_beams.dart';
import 'package:kongrepad/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform, // Otomatik oluşturulan Firebase yapılandırması
    );
    print("✅ Firebase başarıyla başlatıldı!");
  } catch (e) {
    print("❌ Firebase başlatılamadı: $e");
    return;
  }

  PusherBeams beamsClient = PusherBeams.instance;
  beamsClient.start('8b5ebe3c-8106-454b-b4c7-b7c10a9320cf');

  // SharedPreferences ile dil kodunu kontrol et
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? languageCode =
      prefs.getString('languageCode') ?? 'en'; // Varsayılan olarak İngilizce

  runApp(MyApp(locale: Locale(languageCode)));
}

class MyApp extends StatefulWidget {
  final Locale locale;

  const MyApp({Key? key, required this.locale}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) async {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    if (state != null) {
      // Dil tercihlerini kaydet
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
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('tr', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate, // AppLocalizations için
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
      home: const LoginView(), // Başlangıç sayfası
    );
  }
}
