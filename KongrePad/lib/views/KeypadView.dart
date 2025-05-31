import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/Keypad.dart';
import '../utils/app_constants.dart';


class KeypadView extends StatefulWidget {
  const KeypadView({super.key, required this.hallId});

  final int hallId;

  @override
  State<KeypadView> createState() => _KeypadViewState(hallId);
}

class _KeypadViewState extends State<KeypadView> {
  int? hallId;
  Keypad? keypad;
  bool _sending = false;
  bool _loading = true;
  String? questionText;

  _KeypadViewState(this.hallId);

  @override
  void initState() {
    super.initState();
    print('KeypadView initialized');
    print('hallId passed to this view: $hallId');
    getData();
    _subscribeToPusher();
  }
  @override
  void dispose() {
    // KeypadView kapandığında 'keypad-updates' kanalından aboneliği kaldırır
    PusherService().unsubscribeFromChannel('keypad-updates');
    super.dispose();
    }

  Future<void> getData() async {
    print('Starting getData function for hallId: $hallId');

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('Token retrieved: $token');
    if (token == null) {
      print('No token found. Aborting request.');
      return;
    }

    try {
      print('Making API request for active keypad for hallId $hallId...');
      final url = Uri.parse('http://app.kongrepad.com/api/v1/hall/$hallId/active-keypad');
      print('Requesting URL: $url');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Decoded JSON: $jsonData');

        final keypadJson = KeypadJSON.fromJson(jsonData);
        print('Parsed Keypad object: ${keypadJson.data}');

        setState(() {
          keypad = keypadJson.data;
          _loading = false;
          // Artık `keypad` alanını kullanarak soru metnini gösteriyoruz
          questionText = keypad?.keypad?.isNotEmpty == true ? keypad?.keypad : "Soru mevcut değil";
        });

        if (keypad != null) {
          print('Subscribing to Pusher channel: keypad-${keypad!.id}');
          PusherService().subscribeToChannel('keypad-${keypad!.id}');
        } else {
          print('No active keypad data found.');
        }
      } else {
        print('API request failed with status code: ${response.statusCode}');
        _showError("API request failed. Please try again.");
      }
    } catch (e) {
      print('Error occurred during data fetch: $e');
      _showError('Error occurred while fetching data: $e');
    }
    print('getData function completed.');
  }

  Future<void> _subscribeToPusher() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
      await pusher.init(apiKey: "314fc649c9f65b8d7960", cluster: "eu");
      await pusher.connect();

      await pusher.subscribe(channelName: 'keypad-updates');

      pusher.onEvent = (PusherEvent event) {
        print('Pusher event received: ${event.toString()}');

        if (event.channelName == 'keypad-updates' && event.eventName == 'keypad-activated') {
          print('Pusher keypad update received: ${event.data}');

          if (event.data != null && event.data!.isNotEmpty) {
            Map<String, dynamic> jsonData = jsonDecode(event.data!);
            print('Decoded Pusher event data: $jsonData');

            if (jsonData.containsKey('keypad_id')) {
              int keypadId = jsonData['keypad_id'];

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KeypadView(hallId: keypadId),
                ),
              );
            }
          }
        }
      };
    }
  }

  void _showError(String message) {
    print('Error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building KeypadView UI');
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    return SafeArea(
      child: Scaffold(
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : keypad?.options?.isNotEmpty == true
            ? Container(
          height: screenHeight,
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                height: screenHeight * 0.11,
                decoration: const BoxDecoration(
                  color: AppConstants.backgroundBlue,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white, // Border color
                      width: 1, // Border width
                    ),
                  ),
                ),
                child: Text(
                    AppLocalizations.of(context)
                        .translate("please_select_answer"),style:  TextStyle(fontSize: 22, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  questionText ?? "", // Soru metnini gösteriyoruz
                  style: const TextStyle(fontSize: 25, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                  height: screenHeight * 0.65,
                  width: screenWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: keypad!.options!.map((option) {
                      print('Keypad ID: ${keypad?.id}');

                      print('Rendering option: ${option.option} with id: ${option.id}');
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: screenWidth * 1,
                          height: screenHeight*0.10,
                          child: ElevatedButton(
                              onPressed: () {
                                print('Option selected: ${option.option} (ID: ${option.id})');
                                _sendAnswer(option.id!);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: Text(
                                      option.option.toString(),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        )
            : Center(
          child: Text(
            AppLocalizations.of(context).translate("no_active_keypad"),
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _sendAnswer(int answerId) async {
    setState(() {
      _sending = true;
      print('Keypad ID: ${keypad?.id}');
    });

    // Eğer keypad ID null veya 0 ise, bu aşamada bir sorun var demektir.
    if (keypad?.id == null || keypad?.id == 0) {
      print('Error: Keypad ID null or invalid!');
      _showDialog('Hata', 'Keypad ID geçersiz. Lütfen tekrar deneyin.');
      setState(() {
        _sending = false;
      });
      return;
    }

    print('Sending answerId: $answerId for keypadId: ${keypad?.id}');

    // Eğer keypad ID'nin doğru bir değer olduğundan eminsek URL'yi dinamik olarak oluşturuyoruz
    final url = Uri.parse(
        'https://app.kongrepad.com/api/v1/keypad/${keypad?.id}/keypad-vote');
    print('POST URL: $url'); // URL'yi kontrol et

    // İstek gövdesini oluşturuyoruz
    final body = jsonEncode({
      'option': answerId,
      'participant_id': 123, // Geçici olarak participant_id ekliyoruz (gerçek değerle değiştirin)
      'keypad_id': keypad?.id, // Keypad ID'yi ekliyoruz
    });
    print('POST Body: $body'); // Gönderilen JSON'u logluyoruz

    // Tokeni alıyoruz
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Token: $token'); // Token'i kontrol et

    try {
      print('Posting vote to API...');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Authorization header'ı kontrol et
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // HTTP yanıtını logluyoruz
      print('Vote response status: ${response.statusCode}');
      print('Vote response body: ${response.body}');
      print('Keypad ID: ${keypad?.id}');

      // Yanıt durumunu kontrol ediyoruz
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status']) {
          print('Vote submitted successfully.');
          await _showDialog(
            AppLocalizations.of(context).translate('success'),
            AppLocalizations.of(context).translate('submit_vote_success'),
          );
          Navigator.of(context).pop(); // Dialog kapandıktan sonra sayfayı kapat
        } else {
          print('Vote submission failed.');
          _showDialog(
            AppLocalizations.of(context).translate('error'),
            AppLocalizations.of(context).translate('already_voted'),
          );
        }
      } else {
        print('Vote submission failed with status code: ${response.statusCode}');
        _showDialog(
          AppLocalizations.of(context).translate('error'),
          AppLocalizations.of(context).translate('vote_submission_failed'),
        );
      }
    } catch (error) {
      print('Error sending vote: $error');
      _showDialog(
        AppLocalizations.of(context).translate('error'),
        AppLocalizations.of(context).translate('vote_submission_error'),
      );
    } finally {
      setState(() {
        _sending = false;
      });
    }

  }

  // Bu fonksiyon AlertDialog göstermek için kullanılıyor
  Future<void> _showDialog(String title, String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child:  Text(AppLocalizations.of(context).translate("ok")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}

class PusherService {
  static final PusherService _instance = PusherService._internal();
  final Map<String, bool> _subscribedChannels = {};
  bool _isPusherInitialized = false;

  factory PusherService() {
    return _instance;
  }

  PusherService._internal();

  Future<void> initPusher() async {
    if (!_isPusherInitialized) {
      PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
      await pusher.init(apiKey: "314fc649c9f65b8d7960", cluster: "eu");
      await pusher.connect();
      print('Pusher initialized and connected.');
      _isPusherInitialized = true;
    }
  }

  Future<void> subscribeToChannel(String channelName) async {
    await initPusher();

    PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

    if (_subscribedChannels[channelName] == true) {
      print('Already subscribed to channel: $channelName');
      return;
    }

    await pusher.subscribe(channelName: channelName);
    print('Subscribed to Pusher channel: $channelName');

    _subscribedChannels[channelName] = true;
  }

  Future<void> unsubscribeFromChannel(String channelName) async {
    PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

    if (_subscribedChannels[channelName] == true) {
      await pusher.unsubscribe(channelName: channelName);
      print('Unsubscribed from Pusher channel: $channelName');
      _subscribedChannels[channelName] = false;
    }
  }
}
