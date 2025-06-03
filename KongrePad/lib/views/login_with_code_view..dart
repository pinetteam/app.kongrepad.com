import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'MainPageView.dart';
import '../services/alert_service.dart';
import '../utils/app_constants.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginWithCodeView extends StatefulWidget {
  const LoginWithCodeView({super.key});

  @override
  State<LoginWithCodeView> createState() => _LoginWithCodeViewState();
}

class _LoginWithCodeViewState extends State<LoginWithCodeView> {
  final TextEditingController _controller = TextEditingController();

  void _submit() async {
    try {
      print("API isteği gönderiliyor...");

      final deviceInfo = await getDeviceInfo();

      final response = await http.post(
        Uri.parse('https://api.kongrepad.com/api/v1/auth/login'),
        //deneme
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': _controller.text.trim(),
          'device_name': deviceInfo['device_name'],
          'device_id': deviceInfo['device_id'],
          'push_token': 'test-push-token',
          'app_version': deviceInfo['app_version'],
          'os_version': deviceInfo['os_version'],
          'os_type': deviceInfo['os_type'],
          'language': deviceInfo['language'],
          'timezone': deviceInfo['timezone'],
        }),
      );

      print("API yanıt kodu: ${response.statusCode}");
      print("API yanıtı: ${response.body}");

      if (response.statusCode != 200) {
        print("Hata: Sunucudan beklenmeyen bir yanıt geldi.");
        AlertService().showAlertDialog(
          context,
          title: "Hata",
          content:
              "Sunucudan geçerli bir yanıt alınamadı. Hata kodu: ${response.statusCode}",
        );
        return;
      }

      final responseBody = jsonDecode(response.body);

      if (responseBody == null ||
          !responseBody.containsKey('data') ||
          !responseBody['data'].containsKey('token')) {
        print("Hata: Yanıtta 'token' bulunamadı.");
        print("Gönderilen kullanıcı adı: ${_controller.text}");

        AlertService().showAlertDialog(
          context,
          title: "Giriş Başarısız",
          content: "Geçersiz yanıt alındı, lütfen tekrar deneyin.",
        );
        return;
      }

      final token = responseBody['data']['token'];

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      print("Giriş başarılı, ana sayfaya yönlendiriliyor...");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainPageView(title: ''),
          ),
        );
      }
    } catch (e) {
      print("İstisna yakalandı: $e");
      AlertService().showAlertDialog(
        context,
        title: "Hata",
        content: "Bir hata oluştu: $e",
      );
    }
  }

  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String deviceName = '';
    String osVersion = '';
    String osType = '';
    String deviceId = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model ?? 'Unknown';
      osVersion = androidInfo.version.release ?? 'Unknown';
      osType = 'android';
      deviceId = androidInfo.id ?? 'Unknown';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.utsname.machine ?? 'Unknown';
      osVersion = iosInfo.systemVersion ?? 'Unknown';
      osType = 'ios';
      deviceId = iosInfo.identifierForVendor ?? 'Unknown';
    }

    return {
      'device_name': deviceName,
      'device_id': deviceId,
      'app_version': packageInfo.version,
      'os_version': osVersion,
      'os_type': osType,
      'language': 'tr',
      'timezone': DateTime.now().timeZoneName,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: AppLocalizations.of(context).translate('enter_code'),
                hintStyle: const TextStyle(color: Colors.grey),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange),
                  borderRadius: BorderRadius.circular(40),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                    AppConstants.loginButtonOrange),
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.all(15)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              onPressed: _submit,
              child: Text(AppLocalizations.of(context).translate('login')),
            ),
          ],
        ),
      ),
    );
  }
}
