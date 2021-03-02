import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo_api_client/model/daily_intakes_light_report.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:time_machine/time_machine.dart';

class NutritionCalendar extends StatefulWidget {
  final List<DailyIntakesLightReport> dailyIntakesLightReports;
  final void Function(LocalDate date) onDaySelected;
  final Nutrient nutrient;

  NutritionCalendar(
    this.dailyIntakesLightReports, {
    this.onDaySelected,
    this.nutrient,
  })  : assert(dailyIntakesLightReports != null),
        super(key: UniqueKey());

  @override
  _NutritionCalendarState createState() => _NutritionCalendarState();
}

class _NutritionCalendarState extends State<NutritionCalendar> {
  LocalDate _today;
  LocalDate _minDate;
  LocalDate _maxDate;

  CalendarController _calendarController;

  List<DailyIntakesLightReport> _reportsSortedByDateReverse;

  Set<LocalDate> _dailyNormExceededDatesSet;
  Set<LocalDate> _dailyNormUnavailableDatesSet;
  Set<LocalDate> _availableDatesSet;

  @override
  void initState() {
    _today = LocalDate.today();

    _calendarController = CalendarController();

    _reportsSortedByDateReverse = widget.dailyIntakesLightReports
        .sortedBy((e) => e.date.calendarDate, reverse: true)
        .toList();

    _minDate = _reportsSortedByDateReverse.lastOrNull()?.date?.calendarDate;
    _maxDate = _reportsSortedByDateReverse.firstOrNull()?.date?.calendarDate;

    _availableDatesSet =
        _reportsSortedByDateReverse.map((r) => r.date.calendarDate).toSet();

    _dailyNormExceededDatesSet =
        generateDailyNormExceededDates(_reportsSortedByDateReverse).toSet();

    _dailyNormUnavailableDatesSet =
        generateDailyNormUnavailableDates(_reportsSortedByDateReverse).toSet();

    super.initState();
  }

  Iterable<LocalDate> generateDailyNormExceededDates(
    List<DailyIntakesLightReport> reports,
  ) {
    if (widget.nutrient == null) {
      return _reportsSortedByDateReverse
          .where((r) => r.nutrientNormsAndTotals.isAtLeastOneNormExceeded())
          .map((r) => r.date.calendarDate);
    }

    return _reportsSortedByDateReverse.where(
      (r) {
        final consumption = r.nutrientNormsAndTotals
            .getDailyNutrientConsumption(widget.nutrient);

        return consumption.normExceeded == true;
      },
    ).map((r) => r.date.calendarDate);
  }

  Iterable<LocalDate> generateDailyNormUnavailableDates(
    List<DailyIntakesLightReport> reports,
  ) {
    if (widget.nutrient == null) {
      return [];
    }

    return _reportsSortedByDateReverse.where(
      (r) {
        final consumption = r.nutrientNormsAndTotals
            .getDailyNutrientConsumption(widget.nutrient);

        return !consumption.isNormExists;
      },
    ).map((r) => r.date.calendarDate);
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      calendarController: _calendarController,
      startDay: _minDate?.toDateTimeUnspecified(),
      endDay: _maxDate?.toDateTimeUnspecified(),
      initialSelectedDay: _minDate?.toDateTimeUnspecified(),
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.none,
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
      ),
      onDaySelected: (widget.onDaySelected != null) ? _onDaySelected : null,
      headerVisible: false,
      builders: CalendarBuilders(
        dayBuilder: (context, dateTime, _) {
          final date = LocalDate.dateTime(dateTime);
          return _buildCalendarCell(date);
        },
      ),
    );
  }

  Widget _buildCalendarCell(LocalDate date) {
    Color fontColor;
    FontWeight fontWeight = FontWeight.normal;
    BoxDecoration boxDecoration;

    if (_dailyNormUnavailableDatesSet.contains(date)) {
      fontColor = Colors.white;
      fontWeight = FontWeight.bold;
      boxDecoration = const BoxDecoration(
        color: Colors.brown,
        shape: BoxShape.circle,
      );
    } else if (!_availableDatesSet.contains(date)) {
      if (_today < date) {
        fontColor = Colors.grey;
      } else {
        fontColor = null;
      }
    } else if (_dailyNormExceededDatesSet.contains(date)) {
      fontColor = Colors.white;
      fontWeight = FontWeight.bold;
      boxDecoration = const BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
      );
    } else {
      fontColor = Colors.white;
      fontWeight = FontWeight.bold;
      boxDecoration = const BoxDecoration(
        color: Colors.teal,
        shape: BoxShape.circle,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        alignment: Alignment.center,
        decoration: boxDecoration,
        child: Text(
          date.dayOfMonth.toString(),
          style: TextStyle(color: fontColor, fontWeight: fontWeight),
        ),
      ),
    );
  }

  void _onDaySelected(DateTime dateTime, List events, List holidays) {
    final date = LocalDate.dateTime(dateTime);

    widget.onDaySelected(date);
  }

  int getReportPosition(LocalDate date) {
    return _reportsSortedByDateReverse
            .mapIndexed((i, r) => r.date.calendarDate == date ? i : null)
            .firstWhere((i) => i != null) +
        1;
  }

  @override
  void dispose() {
    _calendarController.dispose();

    super.dispose();
  }
}

class NutrientCalendarExplanation extends StatelessWidget {
  const NutrientCalendarExplanation()
      : super(key: const Key('NutrientCalendarExplanation'));

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: _buildDailyNormExplanation(
            appLocalizations.dailyNormExplanationExceeded,
            Colors.redAccent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildDailyNormExplanation(
            appLocalizations.dailyNormExplanationNotExceeded,
            Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyNormExplanation(String text, Color color) {
    return Row(
      children: [
        Container(
          height: 16,
          width: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(text),
        )
      ],
    );
  }
}
