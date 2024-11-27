import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../views/DebateView.dart';
import '../views/KeypadView.dart';

class PusherService {
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _isConnected = false;

  Future<void> initPusher() async {
    if (!_isConnected) {
      try {
        await _pusher.init(
          apiKey: "314fc649c9f65b8d7960",
          cluster: "eu",
        );
        await _pusher.connect();
        _isConnected = true;
        print("Pusher connected successfully.");
      } catch (e) {
        print("Error initializing Pusher: $e");
      }
    }
  }

  Future<void> subscribeToPusher(
      int meetingId, String participantType, BuildContext context) async {
    await initPusher();

    String channelName = 'meeting-$meetingId-$participantType';
    if (_isConnected) {
      try {
        await _pusher.subscribe(
          channelName: channelName,
          onEvent: (event) {
            print("Event received on channel $channelName:");
            print("Event Name: ${event.eventName}");
            print("Event Data: ${event.data}");
            _handlePusherEvent(event, context);
          },
        );
        print("Successfully subscribed to Pusher channel: $channelName");
      } catch (e) {
        print("Error subscribing to channel $channelName: $e");
      }
    }
  }

  void _handlePusherEvent(PusherEvent event, BuildContext context) {
    print('Handling Pusher event: ${event.eventName}');

    // Gelen event verisini kontrol et
    if (event.data != null && event.data!.isNotEmpty) {
      try {
        final eventData = jsonDecode(event.data!);
        if (eventData.containsKey('hall_id')) {
          int hallId = eventData['hall_id'];

          // Keypad Aktif Edildiğinde
          if (event.eventName == 'keypad-activated') {
            print("Navigating to KeypadView for hall_id: $hallId");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KeypadView(hallId: hallId),
              ),
            ).then((_) {
              print("Returned from KeypadView.");
            }).catchError((error) {
              print("Error navigating to KeypadView: $error");
            });
          }

          // Debate Aktif Edildiğinde
          else if (event.eventName == 'debate-activated') {
            print("Navigating to DebateView for hall_id: $hallId");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DebateView(hallId: hallId),
              ),
            ).then((_) {
              print("Returned from DebateView.");
            }).catchError((error) {
              print("Error navigating to DebateView: $error");
            });
          }
        } else {
          print("Error: 'hall_id' not found in event data.");
        }
      } catch (e) {
        print("Error parsing event data: $e");
      }
    } else {
      print("Error: event data is null or empty.");
    }
  }



  Future<void> disconnectPusher() async {
    if (_isConnected) {
      await _pusher.disconnect();
      _isConnected = false;
      print("Pusher disconnected.");
    }
  }
}
