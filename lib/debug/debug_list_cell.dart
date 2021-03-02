import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:nephrogo/ui/general/app_future_builder.dart';
import 'package:nephrogo/ui/general/components.dart';

class DebugListCell extends StatelessWidget {
  final _firebaseMessaging = FirebaseMessaging.instance;

  @override
  Widget build(BuildContext context) {
    return AppFutureBuilder<String>(
      future: _firebaseMessaging.getToken(),
      builder: (context, firebaseToken) {
        return AppListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text('DEBUG'),
          onTap: () => _openDebugDialog(context, firebaseToken),
        );
      },
    );
  }

  Future<void> _openDebugDialog(BuildContext context, String firebaseToken) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('DEBUG'),
          content: SelectableText(firebaseToken),
        );
      },
    );
  }
}
