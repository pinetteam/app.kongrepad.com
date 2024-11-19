
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:kongrepad/utils/app_constants.dart';

import 'package:pusher_beams/pusher_beams.dart';


import 'views/LoginView.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  PusherBeams beamsClient = PusherBeams.instance;

  await beamsClient.start('8dedc4bd-d0d1-4d83-825f-071ab329a328');  // Pusher Beams Instance ID'nizi buraya ekleyin
 // await beamsClient.addDeviceInterest('debug-meeting_2');  // Cihazın abone olacağı "interest" ekleyin


  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppConstants.backgroundBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => LoginView(),
      },
      home:  Scaffold(body: LoginView()),
    );
  }
}
