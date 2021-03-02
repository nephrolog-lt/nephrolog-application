import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo_api_client/model/automatic_peritoneal_dialysis.dart';
import 'package:nephrogo_api_client/model/dialysate_color_enum.dart';

import 'automatic_peritoneal_dialysis_creation_screen.dart';

class AutomaticPeritonealDialysisTile extends StatelessWidget {
  final AutomaticPeritonealDialysis dialysis;
  final _dateTimeFormat = DateFormat.MMMMd().add_Hm();

  AutomaticPeritonealDialysisTile(this.dialysis)
      : assert(dialysis != null),
        super(key: ObjectKey(dialysis));

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: Text(_getTitle(context.appLocalizations)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDialysateColorWarning)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.error_outline, size: 14),
                  ),
                  Text(dialysis.dialysateColor
                      .localizedName(context.appLocalizations)),
                ],
              ),
            ),
          if (dialysis.notes != null && dialysis.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(dialysis.notes),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dialysis.isCompleted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(dialysis.formattedBalance),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(
        Routes.routeAutomaticPeritonealDialysisCreation,
        arguments: AutomaticPeritonealDialysisCreationScreenArguments(dialysis),
      ),
    );
  }

  bool get isDialysateColorWarning {
    return dialysis.dialysateColor != DialysateColorEnum.transparent &&
        dialysis.dialysateColor != DialysateColorEnum.unknown;
  }

  String _getTitle(AppLocalizations appLocalizations) {
    if (dialysis.isCompleted) {
      return _dateTimeFormat
          .format(dialysis.finishedAt.localDateTime.toDateTimeLocal())
          .capitalizeFirst();
    }

    return appLocalizations.dialysisActive;
  }
}
