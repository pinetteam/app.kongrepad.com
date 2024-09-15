import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();

  factory PusherService() {
    return _instance;
  }

  PusherService._internal();

  static Future<void> subscribeToChannel(String channelName) async {
    PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
    await pusher.init(
        apiKey: "314fc649c9f65b8d7960",
        cluster: "eu"
    );
    await pusher.connect();
    pusher.unsubscribe(channelName: channelName);
    pusher.subscribe(channelName: channelName);
  }
}
