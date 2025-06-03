import 'package:flutter/material.dart';

class AlertService {
  void showAlertDialog(BuildContext context,
      {String? title, String? content, VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? 'Uyarı'),
          content: Text(content ?? ''),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                if (onDismiss != null) {
                  onDismiss(); // Call the onDismiss callback if provided
                }
              },
            ),
          ],
        );
      },
    );
  }
}
