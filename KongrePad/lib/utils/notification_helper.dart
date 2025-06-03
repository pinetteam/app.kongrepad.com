import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart'; // AppSettings paketini dahil edin

Future<void> checkNotificationPermission(BuildContext context) async {
  NotificationSettings settings =
      await FirebaseMessaging.instance.getNotificationSettings();

  if (settings.authorizationStatus == AuthorizationStatus.denied ||
      settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bildirim İzni Gerekli"),
          content: const Text(
              "Bildirimlerimizi almak için lütfen bildirim izinlerini açın. Bu sayede etkinliklerden haberdar olabilirsiniz."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialogu kapat
                // Burada başka bir işlem yapmak isterseniz ekleyebilirsiniz.
              },
              child: const Text("Hayır, teşekkürler"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Önce dialogu kapat
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              },
              child: const Text("İzin Ver"),
            ),
          ],
        );
      },
    );
  }
}
