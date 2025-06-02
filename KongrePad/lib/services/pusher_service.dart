import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../views/DebateView.dart';
import '../views/KeypadView.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _isConnecting = false;
  String? _currentChannel;

  factory PusherService() {
    return _instance;
  }

  PusherService._internal();

  Future<void> subscribeToPusher(int meetingId, BuildContext context) async {
    if (_isConnecting) return;

    try {
      _isConnecting = true;

      // Eğer önceki bir bağlantı varsa temizle
      if (_currentChannel != null) {
        await _pusher.unsubscribe(channelName: _currentChannel!);
      }

      await _pusher.init(
          apiKey: "314fc649c9f65b8d7960",
          cluster: "eu",
          onConnectionStateChange: (currentState, previousState) {
            print(
                "Connection state changed from $previousState to $currentState");
          },
          onError: (message, code, error) {
            print("Pusher error: $message, code: $code, error: $error");
          });

      _currentChannel = 'meeting-$meetingId';

      await _pusher.subscribe(
          channelName: _currentChannel!,
          onEvent: (event) {
            print("Event received: ${event.eventName} - ${event.data}");
            _handlePusherEvent(event, context, meetingId);
          });

      await _pusher.connect();
      print(
          "Successfully connected to Pusher and subscribed to meeting-$meetingId");
    } catch (e) {
      print("Pusher error: $e");
    } finally {
      _isConnecting = false;
    }
  }

  void _handlePusherEvent(
      PusherEvent event, BuildContext context, int meetingId) {
    if (event.eventName == "pusher:subscription_succeeded") {
      print("Successfully subscribed to channel");
      return;
    }

    try {
      final data = jsonDecode(event.data ?? "{}");

      switch (event.eventName) {
        case "keypad":
          if (data['hall_id'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KeypadView(hallId: data['hall_id']),
              ),
            );
          }
          break;

        case "debate":
          if (data['hall_id'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DebateView(hallId: data['hall_id']),
              ),
            );
          }
          break;

        default:
          print("Unhandled event: ${event.eventName}");
      }
    } catch (e) {
      print("Error handling Pusher event: $e");
    }
  }

  Future<void> disconnectPusher() async {
    try {
      if (_currentChannel != null) {
        await _pusher.unsubscribe(channelName: _currentChannel!);
        _currentChannel = null;
      }
      await _pusher.disconnect();
      print("Successfully disconnected from Pusher");
    } catch (e) {
      print("Disconnect error: $e");
    }
  }
}
