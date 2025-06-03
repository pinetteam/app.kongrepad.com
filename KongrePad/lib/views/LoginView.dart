import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'MainPageView.dart';
import '../utils/app_constants.dart';
import 'login_with_code_view..dart';
import 'qr_view_example.dart';
import '../l10n/app_localizations.dart'; // AppLocalizations import edildi.
import '../services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  bool _loading = false;

  Future<void> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MainPageView(title: 'Main Page')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _updateLanguage(Locale locale) async {
    // Dil değişikliğini uygulama seviyesinde güncelle
    MyApp.setLocale(context, locale);

    // Dil tercihini SharedPreferences ile kaydet
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);

    // Kullanıcıya dilin değiştiğini göster
    String language = locale.languageCode == 'tr' ? 'Türkçe' : 'English';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language set to $language')),
    );
  }

  void _showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.backgroundBlue,
          title: Text(
            AppLocalizations.of(context).translate('privacy_policy_title'),
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              AppLocalizations.of(context).translate('privacy_policy_content'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).translate('ok')),
            ),
          ],
        );
      },
    );
  }

  Future<String?> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print("FCM Token error: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      String? fcmToken = await getFCMToken();
      final result =
          await AuthService().login(_usernameController.text, fcmToken);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const MainPageView(title: '')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background shapes
          Stack(
            children: [
              Positioned(
                top: -1 * screenHeight,
                left: -1 * screenWidth * 1.6,
                height: screenHeight * 2,
                width: screenWidth * 4.3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: -1 * screenHeight / 2,
                left: -1 * screenWidth / 2,
                height: screenHeight,
                width: screenWidth * 2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppConstants.backgroundBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // Language Selection Icons
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _updateLanguage(const Locale('tr', 'TR'));
                  },
                  child: Image.asset(
                    'assets/icon/turkey.png',
                    width: 30,
                    height: 30,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    _updateLanguage(const Locale('en', 'US'));
                  },
                  child: Image.asset(
                    'assets/icon/uk.png',
                    width: 28,
                    height: 30,
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  // App Icon
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.4),
                      child: Container(
                        color: Colors.white,
                        width: screenWidth * 0.4,
                        height: screenWidth * 0.4,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Image(
                            image: AssetImage('assets/app_icon.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Login Button
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          AppConstants.loginButtonOrange),
                      foregroundColor:
                          WidgetStateProperty.all<Color>(Colors.white),
                      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(12)),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            contentPadding: EdgeInsets.zero,
                            content: SizedBox(
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.9,
                              child: const QRViewExample(),
                            ),
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('login'),
                            style: const TextStyle(fontSize: 25),
                          ),
                          SvgPicture.asset(
                            'assets/icon/chevron.right.svg',
                            color: Colors.white,
                            width: screenWidth * 0.05,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      AppLocalizations.of(context).translate('qr_instructions'),
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text:
                            '${AppLocalizations.of(context).translate('kvkk_acceptance')} ',
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text:
                                '\n${AppLocalizations.of(context).translate('privacy_policy_title')}',
                            style: const TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _showPopup(context);
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          AppConstants.loginWithCodeButtonBlue),
                      foregroundColor:
                          WidgetStateProperty.all<Color>(Colors.black),
                      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(12)),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const AlertDialog(
                            content: LoginWithCodeView(),
                          );
                        },
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('login_with_code'),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
