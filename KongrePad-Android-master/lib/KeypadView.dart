import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/Models/Keypad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import 'PusherService.dart';

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

  _KeypadViewState(this.hallId);

  @override
  void initState() {
    super.initState();
    print('KeypadView initialized');
    print('hallId passed to this view: $hallId');
    getData();
    // Pusher için abone olmayı çağırıyoruz
    _subscribeToPusher();
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
    // Pusher için abonelik
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
      await pusher.init(apiKey: "314fc649c9f65b8d7960", cluster: "eu");
      await pusher.connect();

      // Subscribing to a specific channel
      await pusher.subscribe(channelName: 'keypad-updates');

      // Dinleyiciye gelen olayları yazdırma ve işleme
      // Pusher olaylarını dinlerken
      pusher.onEvent = (PusherEvent event) {
        print('Pusher event received: ${event.toString()}');

        if (event.channelName == 'keypad-updates' && event.eventName == 'keypad-changed') {
          print('Pusher keypad update received: ${event.data}');

          // Veriyi parse et
          if (event.data != null && event.data!.isNotEmpty) {
            Map<String, dynamic> jsonData = jsonDecode(event.data!);
            print('Decoded Pusher event data: $jsonData');

            // Keypad sayfasına yönlendirme
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
                height: screenHeight * 0.1,
                decoration: const BoxDecoration(
                  color: AppConstants.backgroundBlue,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white, // Border color
                      width: 2, // Border width
                    ),
                  ),
                ),
                child: Text(
                  "Anketler",
                  style: TextStyle(fontSize: 25, color: Colors.white),
                ),
              ),
              Text(
                "Fill in our surveys to help us",
                style: TextStyle(fontSize: 25, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                  height: screenHeight * 0.65,
                  width: screenWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: keypad!.options!.map((option) {
                      print('Rendering option: ${option.option} with id: ${option.id}');
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: ElevatedButton(
                              onPressed: () {
                                print('Option selected: ${option.option} (ID: ${option.id})');
                                _sendAnswer(option.id!);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    option.option.toString(),
                                    style: TextStyle(fontSize: 20),
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
            "No active keypad found.",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _sendAnswer(int answerId) async {
    setState(() {
      _sending = true;
    });

    print('Sending answerId: $answerId for keypadId: ${keypad?.id}');
    final url = Uri.parse('https://app.kongrepad.com/api/v1/keypad/${keypad?.id!}/vote');
    final body = jsonEncode({
      'option': answerId,
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      print('Posting vote to API...');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${prefs.getString('token')}',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Vote response status: ${response.statusCode}');
      print('Vote response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        print('Vote submitted successfully.');
        Navigator.of(context).pop();
      } else {
        print('Vote submission failed.');
        _showError('Vote submission failed. Please try again.');
      }
    } catch (error) {
      print('Error sending vote: $error');
      _showError('An error occurred while sending the vote.');
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }
}


class PusherService {
  static final PusherService _instance = PusherService._internal();
  final Map<String, bool> _subscribedChannels = {};
  bool _isPusherInitialized = false;  // Pusher'ın başlatılıp başlatılmadığını izler

  factory PusherService() {
    return _instance;
  }

  PusherService._internal();

  // Pusher'ı sadece bir kez başlatmak için yeni fonksiyon
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
    // Pusher'ı sadece bir kez başlatıyoruz
    await initPusher();

    PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

    // Eğer kanal zaten abone olduysa, tekrar abone olmadan çık
    if (_subscribedChannels[channelName] == true) {
      print('Already subscribed to channel: $channelName');
      return;
    }

    await pusher.subscribe(channelName: channelName);
    print('Subscribed to Pusher channel: $channelName');

    // Kanalı abone listesine ekleyin
    _subscribedChannels[channelName] = true;
  }

  Future<void> unsubscribeFromChannel(String channelName) async {
    PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

    if (_subscribedChannels[channelName] == true) {
      await pusher.unsubscribe(channelName: channelName);
      print('Unsubscribed from Pusher channel: $channelName');
      // Abonelikten çıktığınızda, listeden çıkarın
      _subscribedChannels[channelName] = false;
    }
  }
}

