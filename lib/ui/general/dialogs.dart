import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/ui/general/progress_dialog.dart';

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

Future<bool> showDeleteDialog({
  @required BuildContext context,
  @required Future<void> Function() onDelete,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.appLocalizations.delete),
        content: Text(context.appLocalizations.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.appLocalizations.dialogCancel.toUpperCase()),
          ),
          TextButton(
            onPressed: () async {
              await ProgressDialog(context).showForFuture(onDelete());

              Navigator.of(context).pop(true);
            },
            child: Text(context.appLocalizations.delete.toUpperCase()),
          ),
        ],
      );
    },
  ).then((r) => r ?? false);
}
