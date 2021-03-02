import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo/utils/date_utils.dart';
import 'package:nephrogo_api_client/model/daily_intakes_light_report.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:time_machine/time_machine.dart';

import 'date_time_numeric_chart.dart';

class NutrientBarChart extends StatelessWidget {
  final _percentFormat = NumberFormat.percentPattern();

  final Nutrient nutrient;
  final LocalDate minimumDate;
  final LocalDate maximumDate;
  final List<DailyIntakesLightReport> dailyIntakeLightReports;
  final bool showDataLabels;

  NutrientBarChart({
    Key key,
    @required this.dailyIntakeLightReports,
    @required this.nutrient,
    @required this.minimumDate,
    @required this.maximumDate,
    @required this.showDataLabels,
  }) : super(key: key);

  double get _dailyNorm {
    return dailyIntakeLightReports
        .maxBy((index, e) => e.date.calendarDate)
        ?.nutrientNormsAndTotals
        ?.getDailyNutrientConsumption(nutrient)
        ?.norm
        ?.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: 1.5, child: _cherChart(context));
  }

  Widget _cherChart(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    final nutrientConsumptionName = nutrient.consumptionName(appLocalizations);

    return DateTimeNumericChart(
      series: _getColumnSeries(context).toList(),
      yAxisText: '$nutrientConsumptionName, ${nutrient.scaledDimension}',
      legendToggleSeriesVisibility: false,
      from: minimumDate,
      to: maximumDate,
      decimalPlaces: nutrient.decimalPlaces,
      legendPosition: LegendPosition.bottom,
      showLegend: _dailyNorm != null,
    );
  }

  Iterable<XyDataSeries> _getColumnSeries(BuildContext context) sync* {
    final lastReport = dailyIntakeLightReports.maxBy(
      (_, r) => r.date.calendarDate,
    );

    yield ColumnSeries<DailyIntakesLightReport, DateTime>(
      dataSource:
          dailyIntakeLightReports.sortedBy((e) => e.date.calendarDate).toList(),
      borderRadius: DateTimeNumericChart.rodTopRadius,
      xValueMapper: (report, _) =>
          report.date.calendarDate.toDateTimeUnspecified(),
      yValueMapper: (report, _) {
        final total = report.nutrientNormsAndTotals
            .getDailyNutrientConsumption(nutrient)
            .total;

        return total * nutrient.scale;
      },
      dataLabelMapper: (report, _) {
        final percent = report.nutrientNormsAndTotals
            .getDailyNutrientConsumption(nutrient)
            .normPercentage;
        if (percent != null) {
          return _percentFormat.format(percent);
        }
        return '';
      },
      pointColorMapper: (report, _) => _barColor(report),
      dataLabelSettings: DataLabelSettings(
        isVisible: showDataLabels,
        labelAlignment: ChartDataLabelAlignment.outer,
        showZeroValue: false,
        textStyle: const TextStyle(fontSize: 10),
      ),
      name: nutrient.name(context.appLocalizations),
      color: lastReport != null ? _barColor(lastReport) : Colors.teal,
      isVisibleInLegend: false,
    );

    final dailyNormSeries = _getDailyNormLineSeries(context);
    if (dailyNormSeries != null) {
      yield dailyNormSeries;
    }
  }

  XyDataSeries _getDailyNormLineSeries(BuildContext context) {
    if (_dailyNorm == null) {
      return null;
    }

    final scaledDailyNorm = _dailyNorm * nutrient.scale;
    final dates = DateUtils.generateDates(
      minimumDate.subtractDays(1),
      maximumDate.addDays(1),
    ).toList();

    return LineSeries<LocalDate, DateTime>(
      dataSource: dates,
      xValueMapper: (date, _) => date.toDateTimeUnspecified(),
      yValueMapper: (date, _) => scaledDailyNorm,
      dashArray: [10, 10],
      width: 3,
      opacity: 0.8,
      color: Colors.blue,
      name: context.appLocalizations.dailyNorm,
    );
  }

  Color _barColor(DailyIntakesLightReport report) {
    final normExceeded = report.nutrientNormsAndTotals
        .getDailyNutrientConsumption(nutrient)
        .normExceeded;

    if (normExceeded == null) {
      return Colors.brown;
    } else if (normExceeded) {
      return Colors.redAccent;
    } else {
      return Colors.teal;
    }
  }
}
