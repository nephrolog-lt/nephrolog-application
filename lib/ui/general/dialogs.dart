import 'package:flutter/material.dart';
import 'package:nephrogo/l10n/localizations.dart';

Future<void> showAppDialog({
  @required BuildContext context,
  @required String message,
  String title,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(
          message,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).ok.toUpperCase()),
          ),
        ],
      );
    },
  );
}
