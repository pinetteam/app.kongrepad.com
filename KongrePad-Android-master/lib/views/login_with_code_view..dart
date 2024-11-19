import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
    final response = await http.post(
      Uri.parse('http://app.kongrepad.com/api/v1/auth/login/participant'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': _controller.text,
      }),
    );

    final responseBody = jsonDecode(response.body);
    if (responseBody['token'] != null) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseBody['token']);
     // Navigator.pushNamed(context, '/main');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainPageView(title: '',)), // Ana sayfa buraya
      );    } else {
      AlertService().showAlertDialog(
        context,
        title: 'Hata',
        content: 'Yanlış kod girdiniz!',
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
                filled: true, // Arka plan rengini etkinleştirir
                fillColor: Colors.white, // Arka plan rengini beyaz yapar
                hintText: 'Lütfen Kodunuzu buraya giriniz',
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
           SizedBox(height: 20,),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(AppConstants.loginButtonOrange),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(15)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              onPressed: _submit,
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
