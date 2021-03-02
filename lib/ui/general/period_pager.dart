import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/utils/date_utils.dart';
import 'package:time_machine/time_machine.dart';

typedef PagerBodyBuilder = Widget Function(
  BuildContext context,
  Widget header,
  LocalDate from,
  LocalDate to,
);

typedef OnPageChanged = void Function(
  LocalDate from,
  LocalDate to,
);

enum PeriodPagerType {
  daily,
  weekly,
  monthly,
}

class PeriodPager extends StatelessWidget {
  final PeriodPagerType pagerType;

  final LocalDate earliestDate;
  final LocalDate initialDate;

  final PagerBodyBuilder bodyBuilder;

  const PeriodPager({
    Key key,
    @required this.pagerType,
    @required this.earliestDate,
    @required this.initialDate,
    @required this.bodyBuilder,
  })  : assert(earliestDate != null),
        assert(initialDate != null),
        assert(bodyBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (pagerType) {
      case PeriodPagerType.daily:
        return DailyPager(
          earliestDate: earliestDate,
          initialDate: initialDate,
          bodyBuilder: bodyBuilder,
        );
      case PeriodPagerType.weekly:
        return WeeklyPager(
          earliestDate: earliestDate,
          initialDate: initialDate,
          bodyBuilder: bodyBuilder,
        );
      case PeriodPagerType.monthly:
        return MonthlyPager(
          earliestDate: earliestDate,
          initialDate: initialDate,
          bodyBuilder: bodyBuilder,
        );
    }

    throw ArgumentError.value(pagerType);
  }
}

class DailyPager extends StatelessWidget {
  final _dayFormatter = DateFormat('EEEE, MMMM d');

  final OnPageChanged onPageChanged;

  final LocalDate earliestDate;
  final LocalDate initialDate;

  final PagerBodyBuilder bodyBuilder;

  DailyPager({
    Key key,
    @required this.earliestDate,
    @required this.initialDate,
    @required this.bodyBuilder,
    this.onPageChanged,
  })  : assert(earliestDate != null),
        assert(initialDate != null),
        assert(bodyBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = LocalDate.today();
    final dates = DateUtils.generateDates(earliestDate, today).toList();

    final initialFromDateIndex = dates.indexOf(initialDate);
    assert(initialFromDateIndex != -1);

    return _PeriodPager(
      bodyBuilder: bodyBuilder,
      headerTextBuilder: _buildHeaderText,
      allFromDates: dates,
      initialFromDate: dates[initialFromDateIndex],
      dateFromToDateTo: _dateFromToDateTo,
      onPageChanged: onPageChanged,
    );
  }

  LocalDate _dateFromToDateTo(LocalDate from) => from;

  Widget _buildHeaderText(BuildContext context, LocalDate from, LocalDate to) {
    return Text(_dayFormatter
        .format(
          from.toDateTimeUnspecified(),
        )
        .capitalizeFirst());
  }
}

class WeeklyPager extends StatelessWidget {
  final dateFormatter = DateFormat.MMMMd();
  final _monthFormatter = DateFormat('MMMM ');

  final LocalDate earliestDate;
  final LocalDate initialDate;

  final PagerBodyBuilder bodyBuilder;

  WeeklyPager({
    Key key,
    @required this.earliestDate,
    @required this.initialDate,
    @required this.bodyBuilder,
  })  : assert(earliestDate != null),
        assert(initialDate != null),
        assert(bodyBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = LocalDate.today();
    final dates = DateUtils.generateWeekDates(earliestDate, today).toList();

    final initialFromDateIndex = dates.indexOf(
      DateUtils.getFirstDayOfWeek(initialDate),
    );
    assert(initialFromDateIndex != -1);

    return _PeriodPager(
      bodyBuilder: bodyBuilder,
      headerTextBuilder: _buildHeaderText,
      allFromDates: dates,
      initialFromDate: dates[initialFromDateIndex],
      dateFromToDateTo: _dateFromToDateTo,
    );
  }

  LocalDate _dateFromToDateTo(LocalDate from) {
    return DateUtils.getLastDayOfWeek(from);
  }

  Widget _buildHeaderText(BuildContext context, LocalDate from, LocalDate to) {
    if (from.monthOfYear == to.monthOfYear) {
      final formattedFrom = _monthFormatter
          .format(from.toDateTimeUnspecified())
          .capitalizeFirst();
      return Text('$formattedFrom${from.dayOfMonth} – ${to.dayOfMonth}');
    }

    return Text(
        '${dateFormatter.format(from.toDateTimeUnspecified()).capitalizeFirst()} – '
        '${dateFormatter.format(to.toDateTimeUnspecified()).capitalizeFirst()}');
  }
}

class MonthlyPager extends StatelessWidget {
  static final monthFormatter = DateFormat.yMMMM();

  final LocalDate earliestDate;
  final LocalDate initialDate;

  final PagerBodyBuilder bodyBuilder;

  const MonthlyPager({
    Key key,
    @required this.earliestDate,
    @required this.initialDate,
    @required this.bodyBuilder,
  })  : assert(earliestDate != null),
        assert(initialDate != null),
        assert(bodyBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = LocalDate.today();
    final dates = DateUtils.generateMonthDates(earliestDate, today).toList();

    final initialFromDateIndex =
        dates.indexOf(DateUtils.getFirstDayOfMonth(initialDate));

    assert(initialFromDateIndex != -1);

    return _PeriodPager(
      bodyBuilder: bodyBuilder,
      headerTextBuilder: _buildHeaderText,
      allFromDates: dates,
      initialFromDate: dates[initialFromDateIndex],
      dateFromToDateTo: _dateFromToDateTo,
    );
  }

  LocalDate _dateFromToDateTo(LocalDate from) {
    return DateUtils.getLastDayOfCurrentMonth(from);
  }

  Widget _buildHeaderText(BuildContext context, LocalDate from, LocalDate to) {
    return Text(monthFormatter
        .format(
          from.toDateTimeUnspecified(),
        )
        .capitalizeFirst());
  }
}

class _PeriodPager extends StatefulWidget {
  final List<LocalDate> allFromDates;
  final LocalDate initialFromDate;

  final LocalDate Function(LocalDate from) dateFromToDateTo;

  final OnPageChanged onPageChanged;
  final PagerBodyBuilder bodyBuilder;
  final Widget Function(
    BuildContext context,
    LocalDate from,
    LocalDate to,
  ) headerTextBuilder;

  const _PeriodPager({
    Key key,
    @required this.allFromDates,
    @required this.initialFromDate,
    @required this.bodyBuilder,
    @required this.headerTextBuilder,
    @required this.dateFromToDateTo,
    this.onPageChanged,
  })  : assert(initialFromDate != null),
        assert(allFromDates != null),
        assert(bodyBuilder != null),
        assert(headerTextBuilder != null),
        assert(dateFromToDateTo != null),
        super(key: key);

  @override
  _PeriodPagerState createState() => _PeriodPagerState();
}

class _PeriodPagerState extends State<_PeriodPager> {
  static const _animationDuration = Duration(milliseconds: 400);

  List<LocalDate> _dates;

  PageController _pageController;

  @override
  void initState() {
    super.initState();

    _dates = widget.allFromDates.sortedBy((e) => e, reverse: true).toList();

    final initialIndex = _dates.indexOf(widget.initialFromDate);
    assert(initialIndex != -1);

    _pageController = PageController(
      initialPage: initialIndex,
      viewportFraction: 0.99999,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      reverse: true,
      itemCount: _dates.length,
      onPageChanged: widget.onPageChanged != null
          ? (index) {
              final from = _dates[index];
              final to = widget.dateFromToDateTo(from);

              widget.onPageChanged(from, to);
            }
          : null,
      itemBuilder: (context, index) {
        final from = _dates[index];
        final to = widget.dateFromToDateTo(from);

        final header = _buildDateSelectionSection(index, from, to);

        return widget.bodyBuilder(context, header, from, to);
      },
    );
  }

  bool hasNextDateRange(int index) => index > 0;

  bool hasPreviousDateRange(int index) => index + 1 < _dates.length;

  Future<void> advanceToNextDateRange() {
    return _pageController.previousPage(
        duration: _animationDuration, curve: Curves.ease);
  }

  Future<void> advanceToPreviousDateRange() {
    return _pageController.nextPage(
        duration: _animationDuration, curve: Curves.ease);
  }

  Widget _buildDateSelectionSection(int index, LocalDate from, LocalDate to) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 32,
          icon: const Icon(
            Icons.navigate_before,
          ),
          onPressed:
              hasPreviousDateRange(index) ? advanceToPreviousDateRange : null,
        ),
        Expanded(
          child: DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText1,
            child: widget.headerTextBuilder(context, from, to),
          ),
        ),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.navigate_next),
          onPressed: hasNextDateRange(index) ? advanceToNextDateRange : null,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }
}
