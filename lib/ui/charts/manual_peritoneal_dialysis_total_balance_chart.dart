import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo_api_client/model/daily_health_status.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:time_machine/time_machine.dart';

import 'date_time_numeric_chart.dart';

class ManualPeritonealDialysisTotalBalanceChart extends StatelessWidget {
  final LocalDate minimumDate;
  final LocalDate maximumDate;
  final List<DailyHealthStatus> dailyHealthStatuses;

  const ManualPeritonealDialysisTotalBalanceChart({
    Key key,
    @required this.dailyHealthStatuses,
    @required this.minimumDate,
    @required this.maximumDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: 1.5, child: _getChart(context));
  }

  Widget _getChart(BuildContext context) {
    return DateTimeNumericChart(
      yAxisText: '${context.appLocalizations.dailyBalance}, ml',
      from: minimumDate,
      to: maximumDate,
      decimalPlaces: 0,
      series: [
        ColumnSeries<DailyHealthStatus, DateTime>(
          dataSource:
              dailyHealthStatuses.sortedBy((e) => e.date.calendarDate).toList(),
          xValueMapper: (s, _) => s.date.calendarDate.toDateTimeUnspecified(),
          yValueMapper: (s, _) => s.totalManualPeritonealDialysisBalance,
          pointColorMapper: (s, _) => s.totalManualPeritonealDialysisBalance < 0
              ? Colors.teal
              : Colors.redAccent,
          name: context.appLocalizations.dailyBalance,
        )
      ],
    );
  }
}
