import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/Debate.dart';
import '../utils/app_constants.dart';

class DebateView extends StatefulWidget {
  const DebateView({super.key, required this.hallId});

  final int hallId;

  @override
  State<DebateView> createState() => _DebateViewState(hallId);
}

class _DebateViewState extends State<DebateView> {
  int? hallId;
  Debate? debate;
  bool _sending = false;
  bool _loading = true;

  _DebateViewState(this.hallId);

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print("Debug: Token fetched from SharedPreferences: $token");

    if (token == null) {
      print("Error: Token is null. Redirecting to login.");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final url = Uri.parse(
          'http://app.kongrepad.com/api/v1/hall/$hallId/active-debate');
      print("Requesting data from: $url");
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      print("Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Response data: $jsonData");
        final debateJson = DebateJSON.fromJson(jsonData);
        setState(() {
          debate = debateJson.data;
          _loading = false;
        });
        print("Debate data loaded successfully");
      } else {
        print("Error: ${response.body}");
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> _subscribeToPusher() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("Subscribing to Pusher with token: $token");

    if (token != null) {
      PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
      await pusher.init(apiKey: "314fc649c9f65b8d7960", cluster: "eu");
      await pusher.connect();
      print("Connected to Pusher");

      final channelName = 'meeting-${widget.hallId}-attendee';
      print("Subscribing to channel: $channelName");
      await pusher.subscribe(channelName: channelName);

      pusher.onEvent = (PusherEvent event) {
        print('--- New Event Received ---');
        print('Event Name: ${event.eventName}');
        print('Event Data: ${event.data}');

        if (event.eventName.startsWith('pusher:')) {
          print(
              'Pusher system event: ${event.eventName} received and ignored.');
          return;
        }

        if (event.data == null || event.data!.isEmpty) {
          print('No data received in Pusher event.');
          return;
        }

        print('--- Processing Event Data ---');
        final eventName = event.eventName;
        print('Event name: $eventName');

        if (eventName == 'debate' || eventName == 'debate-activated') {
          try {
            final jsonData = jsonDecode(event.data!);
            print('Parsed event data: $jsonData');

            if (!jsonData.containsKey('hall_id')) {
              print('Error: No hall_id found in event data.');
              return;
            }

            final eventHallId = jsonData['hall_id'].toString();
            final widgetHallId = widget.hallId.toString();

            print('Event hall_id: $eventHallId');
            print('Widget hall_id: $widgetHallId');

            if (eventHallId == widgetHallId) {
              print('hall_id matched! Reloading debate data...');
              getData();
            } else {
              print('Incorrect Hall ID: ${jsonData['hall_id']}');
            }
          } catch (e) {
            print('Error parsing event data: $e');
          }
        } else {
          print('Unhandled event type: $eventName');
        }

        print('--- Event Processing Completed ---');
      };
    }
  }

  @override
  void initState() {
    super.initState();
    print("DebateView initialized with hallId: $hallId");
    getData();
    _subscribeToPusher();
  }

  @override
  Widget build(BuildContext context) {
    print("Building DebateView");
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
            : Container(
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
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: screenWidth,
                        child: Text(
                          AppLocalizations.of(context).translate('debate'),
                          style: const TextStyle(
                              fontSize: 25, color: Colors.white),
                        ),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)
                          .translate('please_select_option'),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: debate != null
                          ? SizedBox(
                              height: screenHeight * 0.65,
                              width: screenWidth,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: debate!.teams!.map((team) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: screenWidth * 0.8,
                                      child: ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStateProperty.all<Color>(
                                                  AppConstants
                                                      .buttonLightPurple),
                                          foregroundColor:
                                              WidgetStateProperty.all<Color>(
                                                  Colors.white),
                                          padding: WidgetStateProperty.all<
                                              EdgeInsetsGeometry>(
                                            const EdgeInsets.all(12),
                                          ),
                                          shape: WidgetStateProperty.all<
                                              OutlinedBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final result =
                                              await _checkPreviousAnswer();
                                          if (result) {
                                            AppLocalizations.of(context)
                                                .translate('error');
                                            AppLocalizations.of(context)
                                                .translate('already_voted');
                                          } else {
                                            _sendAnswer(1,
                                                team.id!); // İlgili `answerId` ve `team.id` gönderiliyor
                                          }
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            team.logoName != null
                                                ? Image.network(
                                                    'https://app.kongrepad.com/storage/team-logos/${team.logoName}.${team.logoExtension}',
                                                    width: 150,
                                                    height: 150,
                                                    fit: BoxFit.contain,
                                                  )
                                                : Text(team.title.toString()),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)
                                  .translate('no_active_debate'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<bool> _checkPreviousAnswer() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final participantId = prefs.getInt('participant_id');
    final debateId = debate?.id;

    // Önceden oy verilen debate ID'lerini kontrol et
    List<String>? answeredDebates =
        prefs.getStringList('answeredDebates') ?? [];
    return answeredDebates.contains('$participantId-$debateId');
  }

  Future<void> _sendAnswer(int answerId, int teamId) async {
    setState(() {
      _sending = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final participantId = prefs.getInt('participant_id');
    final debateId = debate?.id;

    print("Debug: Token: $token");
    print("Debug: Participant ID: $participantId");
    print("Debug: Debate ID: $debateId");

    if (token == null || participantId == null || debateId == null) {
      await _showDialog(
        AppLocalizations.of(context).translate('error'),
        AppLocalizations.of(context).translate('missing_info'),
      );

      print("Error: Missing token, participant ID, or debate ID.");
      Navigator.pushReplacementNamed(context, '/login');
      setState(() {
        _sending = false;
      });
      return;
    }

    final url = Uri.parse(
        'https://app.kongrepad.com/api/v1/debate/$debateId/debate-vote');
    final body = jsonEncode({
      'team': teamId,
      'participant_id': participantId,
      'debate_id': debateId,
    });

    print("Sending POST request to $url with body: $body");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true) {
          await _showDialog(
            AppLocalizations.of(context).translate('success'),
            AppLocalizations.of(context).translate('vote_send_success'),
          );

          // Oy başarıyla gönderildiyse debate ID'sini kaydet
          List<String>? answeredDebates =
              prefs.getStringList('answeredDebates') ?? [];
          answeredDebates.add('$participantId-$debateId');
          prefs.setStringList('answeredDebates', answeredDebates);

          Navigator.of(context).pop(); // İşlem başarılı olursa sayfayı kapat
        } else {
          await _showDialog(
            AppLocalizations.of(context).translate('error'),
            AppLocalizations.of(context).translate('vote_send_error'),
          );
        }
      } else if (response.statusCode == 401) {
        await _showDialog(
            AppLocalizations.of(context).translate('unauthorized_access'),
            AppLocalizations.of(context).translate('missing_info'));
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        await _showDialog(
          AppLocalizations.of(context).translate('error'),
          AppLocalizations.of(context).translate('vote_send_error'),
        );
      }
    } catch (error) {
      print("Error while sending answer: $error");
      await _showDialog(
        AppLocalizations.of(context).translate('error'),
        AppLocalizations.of(context).translate('vote_send_error'),
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
              child: Text(
                AppLocalizations.of(context).translate('ok'),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
            ),
          ],
        );
      },
    );
  }
}
