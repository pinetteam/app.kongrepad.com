import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'MainPageView.dart';
import '../services/alert_service.dart';
import '../utils/app_constants.dart';

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

      final response = await http.post(
        Uri.parse('http://app.kongrepad.com/api/v1/auth/login/participant'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _controller.text,
        }),
      );

      print("API yanıt kodu: ${response.statusCode}");
      print("API yanıtı: ${response.body}");

      if (response.statusCode != 200) {
        print("Hata: Sunucudan beklenmeyen bir yanıt geldi.");
        AlertService().showAlertDialog(
          context,
          title: "Hata",
          content: "Sunucudan geçerli bir yanıt alınamadı. Hata kodu: ${response.statusCode}",
        );
        return;
      }

      final responseBody = jsonDecode(response.body);

      if (responseBody == null || !responseBody.containsKey('token')) {
        print("Hata: Yanıtta 'token' bulunamadı.");
        print("Gönderilen kullanıcı adı: ${_controller.text}");

        AlertService().showAlertDialog(
          context,
          title: "Giriş Başarısız",
          content: "Geçersiz yanıt alındı, lütfen tekrar deneyin.",
        );
        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseBody['token']);

      print("Giriş başarılı, ana sayfaya yönlendiriliyor...");
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MainPageView(title: ''),

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
                hintStyle: TextStyle(color: Colors.grey),
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
            SizedBox(
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
