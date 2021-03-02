import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/ui/charts/numeric_chart.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:time_machine/time_machine.dart';

class ManualPeritonealDialysisDayBalanceChart extends StatelessWidget {
  final LocalDate date;
  final Iterable<ManualPeritonealDialysis> manualPeritonealDialysis;

  const ManualPeritonealDialysisDayBalanceChart({
    Key key,
    @required this.manualPeritonealDialysis,
    @required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NumericChart(
      primaryXAxis: CategoryAxis(),
      series: _getColumnSeries(context).toList(),
      yAxisText: "${context.appLocalizations.balance}, ml",
      decimalPlaces: 0,
      showLegend: false,
    );
  }

  Iterable<XyDataSeries> _getColumnSeries(BuildContext context) sync* {
    final dialysis = manualPeritonealDialysis
        .sortedBy((e) => e.startedAt.toInstant())
        .toList();

    yield BarSeries<ManualPeritonealDialysis, String>(
      dataSource: dialysis,
      xValueMapper: (d, _) =>
          TimeOfDay.fromDateTime(d.startedAt.localDateTime.toDateTimeLocal())
              .format(context),
      yValueMapper: (d, i) => d.balance,
      dataLabelSettings: DataLabelSettings(
        isVisible: true,
        labelAlignment: ChartDataLabelAlignment.outer,
      ),
      pointColorMapper: (d, _) => d.dialysisSolution.color,
      name: context.appLocalizations.balance,
    );
  }
}
