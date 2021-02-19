import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/models/graph.dart';

class AppBarChart extends StatefulWidget {
  final AppBarChartData data;

  const AppBarChart({Key key, @required this.data}) : super(key: key);

  @override
  State<AppBarChart> createState() => _AppBarChart();
}

class _AppBarChart extends State<AppBarChart> {
  final Duration animDuration = const Duration(milliseconds: 250);
  int touchedIndex;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyText1.color;

    return BarChart(
      BarChartData(
        maxY: widget.data.maxY,
        minY: widget.data.minY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.grey,
              maxContentWidth: 200,
              fitInsideHorizontally: widget.data.fitInsideHorizontally,
              fitInsideVertically: widget.data.fitInsideVertically,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  widget.data.groups[groupIndex].rods[rodIndex].tooltip,
                  const TextStyle(color: Colors.yellow),
                );
              }),
          touchCallback: (barTouchResponse) {
            setState(() {
              if (barTouchResponse.spot != null &&
                  barTouchResponse.touchInput is! FlPanEnd &&
                  barTouchResponse.touchInput is! FlLongPressEnd) {
                touchedIndex = barTouchResponse.spot.touchedBarGroupIndex;
              } else {
                touchedIndex = -1;
              }
            });
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: SideTitles(
            showTitles: true,
            getTextStyles: (value) {
              final group = widget.data.groups[value.toInt()];

              return TextStyle(
                color: group.isSelected ? Colors.teal : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              );
            },
            margin: 12,
            getTitles: (double value) {
              return widget.data.groups[value.toInt()].text;
            },
          ),
          leftTitles: SideTitles(
            margin: 8,
            getTextStyles: (v) => TextStyle(color: textColor, fontSize: 11),
            showTitles: widget.data.showLeftTitles,
            interval: widget.data.showLeftTitles
                ? widget.data.interval ?? _calculateInterval()
                : null,
          ),
        ),
        gridData: FlGridData(
          show: widget.data.interval != null,
          horizontalInterval: widget.data.interval,
          checkToShowHorizontalLine: (value) {
            if (widget.data.dashedHorizontalLine == null) {
              return false;
            }
            return (value - widget.data.dashedHorizontalLine).abs() < 1e-6;
          },
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.teal,
              dashArray: [5, 5],
              strokeWidth: 2,
            );
          },
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: showingGroups(),
      ),
      swapAnimationDuration: animDuration,
    );
  }

  double _calculateInterval() {
    var range = widget.data.maxY;
    range ??= widget.data.groups.expand((e) => e.rods.map((e) => e.y)).max();

    if (range == null) {
      return null;
    }

    if (widget.data.minY != null) {
      range -= widget.data.minY;
    }

    return max(1.0, (range / 5).ceilToDouble());
  }

  List<BarChartGroupData> showingGroups() {
    return widget.data.groups.map(
      (group) {
        final x = group.x;
        final isTouched = x == touchedIndex;

        return BarChartGroupData(
          x: x,
          barRods: group.rods.map(
            (rod) {
              final y = rod.y.toDouble();

              final rodStackItems = rod.rodStackItems
                  ?.map(
                    (rs) => BarChartRodStackItem(rs.fromY, rs.toY, rs.color),
                  )
                  ?.toList();

              return BarChartRodData(
                y: y,
                colors: isTouched ? [Colors.orange] : [rod.barColor],
                width: widget.data.barWidth,
                borderRadius:
                    BorderRadius.all(Radius.circular(widget.data.rodRadius)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: rod.backDrawRodY != null,
                  y: rod.backDrawRodY,
                  colors: [Colors.grey],
                ),
                rodStackItems: rodStackItems,
              );
            },
          ).toList(),
        );
      },
    ).toList();
  }
}
