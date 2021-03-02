import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/ui/tabs/nutrition/nutrition_calendar.dart';
import 'package:nephrogo/ui/tabs/nutrition/nutrition_components.dart';
import 'package:nephrogo_api_client/model/daily_intakes_light_report.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:time_machine/time_machine.dart';

import 'nutrition_summary_components.dart';

class NutritionMonthlyReportsList extends StatefulWidget {
  final List<DailyIntakesLightReport> reports;
  final Widget header;

  NutritionMonthlyReportsList({
    Key key,
    @required this.reports,
    @required this.header,
  })  : assert(reports != null),
        assert(reports.isNotEmpty),
        assert(header != null),
        super(key: key);

  @override
  NutritionMonthlyReportsListState createState() =>
      NutritionMonthlyReportsListState();
}

class NutritionMonthlyReportsListState
    extends State<NutritionMonthlyReportsList> {
  ItemScrollController _itemScrollController;

  List<DailyIntakesLightReport> reportsReverseSorted;

  @override
  void initState() {
    super.initState();

    _itemScrollController = ItemScrollController();
    reportsReverseSorted = widget.reports
        .sortedBy(
          (e) => e.date.calendarDate,
          reverse: true,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemCount: reportsReverseSorted.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return DateSwitcherHeaderSection(
            header: widget.header,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: NutritionCalendar(
                  reportsReverseSorted,
                  onDaySelected: (dt) =>
                      _onSelectionChanged(dt, reportsReverseSorted),
                ),
              ),
            ],
          );
        }
        final dailyIntakesReport = reportsReverseSorted[index - 1];

        return DailyIntakesReportSection(dailyIntakesReport);
      },
    );
  }

  void _onSelectionChanged(
    LocalDate date,
    List<DailyIntakesLightReport> reports,
  ) {
    final position = getReportPosition(date, reports);

    _itemScrollController.jumpTo(index: position);
  }

  int getReportPosition(
    LocalDate date,
    List<DailyIntakesLightReport> reports,
  ) {
    return reports
            .mapIndexed((i, r) => r.date.calendarDate == date ? i : null)
            .firstWhere((i) => i != null) +
        1;
  }
}

class NutritionWeeklyReportsList extends StatelessWidget {
  final List<DailyIntakesLightReport> reports;
  final Widget header;

  NutritionWeeklyReportsList({
    Key key,
    @required this.reports,
    @required this.header,
  })  : assert(reports != null),
        assert(reports.isNotEmpty),
        assert(header != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportsReverseSorted =
        reports.sortedBy((e) => e.date.calendarDate, reverse: true).toList();

    return ListView.builder(
      itemCount: reportsReverseSorted.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return DateSwitcherHeaderSection(header: header);
        }
        final dailyIntakesReport = reportsReverseSorted[index - 1];

        return DailyIntakesReportSection(dailyIntakesReport);
      },
    );
  }
}
