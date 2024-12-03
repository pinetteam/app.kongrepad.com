import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kongrepad/utils/app_constants.dart';
import 'package:kongrepad/views/MainPageView.dart';
import 'package:pusher_beams/pusher_beams.dart';
import 'views/LoginView.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  PusherBeams beamsClient = PusherBeams.instance;
  beamsClient.start('8b5ebe3c-8106-454b-b4c7-b7c10a9320cf');
  beamsClient.addDeviceInterest('debug-meeting-3-attendee');

  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],

      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppConstants.backgroundBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => LoginView(),
        '/main': (context) => MainPageView(title: '',),

      },
      home: Scaffold(body: LoginView()),
    );
  }
}
