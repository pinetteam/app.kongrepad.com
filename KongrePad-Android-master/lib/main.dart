import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kongrepad/utils/app_constants.dart';
import 'package:kongrepad/views/LoginView.dart';
import 'package:kongrepad/views/MainPageView.dart';
import 'package:pusher_beams/pusher_beams.dart';
import 'package:kongrepad/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  PusherBeams beamsClient = PusherBeams.instance;
  beamsClient.start('8b5ebe3c-8106-454b-b4c7-b7c10a9320cf');

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? languageCode = prefs.getString('languageCode') ?? 'en';

  runApp(MyApp(locale: Locale(languageCode)));
}

class MyApp extends StatefulWidget {
  final Locale locale;

  const MyApp({Key? key, required this.locale}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
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
      navigatorObservers: [routeObserver],
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
        '/login': (context) => LoginView(),
        '/main': (context) => MainPageView(title: ''),
      },
      home: const LoginView(),
    );
  }
}
