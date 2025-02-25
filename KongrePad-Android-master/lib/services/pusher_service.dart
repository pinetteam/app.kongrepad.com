import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../views/DebateView.dart';
import '../views/KeypadView.dart';

class PusherService {
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _isConnected = false;
  String? _lastEventName; // Son işlenen event'i takip eder

  Future<void> initPusher() async {
    if (!_isConnected) {
      try {
        await _pusher.init(
          apiKey: "314fc649c9f65b8d7960", // Pusher API Key
          cluster: "eu", // Cluster bilgisi
        );
        await _pusher.connect();
        _isConnected = true;
        print("Pusher connected successfully.");
      } catch (e) {
        print("Error initializing Pusher: $e");
      }
    }
  }

  Future<void> subscribeToPusher(int meetingId, BuildContext context) async {
    await initPusher();

    String channelName = 'meeting-$meetingId';

    // Eski kanal varsa temizle
    var channel = await _pusher.getChannel(channelName);
    if (channel != null) {
      print("Unsubscribing from existing channel: $channelName");
      await _pusher.unsubscribe(channelName: channelName);
    }

    // Yeni kanala abone ol
    await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        print("Event received on channel $channelName:");
        print("Event Name: ${event.eventName}");
        print("Event Data: ${event.data}");
        _handlePusherEvent(event, context, meetingId);
      },
    );

    print("Subscribed to channel: $channelName");
  }

  void _handlePusherEvent(
      PusherEvent event, BuildContext context, int meetingId) {
    if (event.eventName == "pusher:subscription_succeeded") {
      print("Subscription succeeded event ignored.");
      return;
    }

    if (event.data != null && event.data!.isNotEmpty) {
      try {
        final data = jsonDecode(event.data!);

        // Aynı event'in tekrar çalışmasını engelle
        if (_lastEventName == event.eventName && data['hall_id'] == null) {
          print("Duplicate event ignored: ${event.eventName}");
          return;
        }
        _lastEventName = event.eventName;

        if (event.eventName == "keypad") {
          // Keypad event'i için KeypadView aç
          if (data.containsKey('hall_id')) {
            int hallId = data['hall_id'];
            print("Navigating to KeypadView for hall_id: $hallId");

            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => KeypadView(hallId: hallId)),
            ).then((_) {
              print("Returned from KeypadView.");
              subscribeToPusher(meetingId, context); // Kanalı yenile
            });
          } else {
            print("Error: 'hall_id' not found in keypad event data.");
          }
        } else if (event.eventName == "debate") {
          // Debate event'i için DebateView aç
          if (data.containsKey('hall_id')) {
            int hallId = data['hall_id'];
            print("Navigating to DebateView for hall_id: $hallId");

            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DebateView(hallId: hallId)),
            ).then((_) {
              print("Returned from DebateView.");
              subscribeToPusher(meetingId, context); // Kanalı yenile
            });
          } else {
            print("Error: 'hall_id' not found in debate event data.");
          }
        } else {
          print("Unhandled event name: ${event.eventName}");
        }
      } catch (e) {
        print("Error parsing event data: $e");
      }
    } else {
      print("Error: Event data is null or empty.");
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
