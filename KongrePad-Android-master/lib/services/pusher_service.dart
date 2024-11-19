import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _isConnected = false;

  Future<void> initPusher() async {
    if (!_isConnected) {
      try {
        await _pusher.init(
          apiKey: "314fc649c9f65b8d7960", // Pusher API anahtarınızı burada belirtin
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

  Future<void> subscribeToPusher(int meetingId, String participantType) async {
    await initPusher(); // Pusher'ın başlatılmasını sağlamak için çağırıyoruz

    String channelName = 'meeting-$meetingId-$participantType';
    if (_isConnected) {
      try {
        await _pusher.subscribe(
          channelName: channelName,
          onEvent: (event) {
            print("Event received on channel $channelName:");
            print("Event Name: ${event.eventName}");
            print("Event Data: ${event.data}");
            _handlePusherEvent(event);
          },
        );
        print("Successfully subscribed to Pusher channel: $channelName");
      } catch (e) {
        print("Error subscribing to channel $channelName: $e");
      }
    }
  }

  void _handlePusherEvent(PusherEvent event) {
    // Gelen event'leri işleyin
    print('Handling Pusher event: ${event.eventName}');
    // Örneğin, event eventName 'debate' veya 'debate-activated' ise
    if (event.eventName == 'debate' || event.eventName == 'debate-activated') {
      print("Debate event received: ${event.data}");
      // Debate ile ilgili işlem yapabilirsiniz, örneğin kullanıcıyı bir ekrana yönlendirme
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
