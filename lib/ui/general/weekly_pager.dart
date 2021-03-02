import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/extensions/string_extensions.dart';
import 'package:nephrogo/utils/date_utils.dart';
import 'package:time_machine/time_machine.dart';

class WeeklyPager<T> extends StatefulWidget {
  final ValueNotifier<T> valueChangeNotifier;
  final Widget Function(LocalDate from, LocalDate to, T value) bodyBuilder;
  final LocalDate Function() earliestDate;

  const WeeklyPager({
    Key key,
    @required this.valueChangeNotifier,
    @required this.bodyBuilder,
    @required this.earliestDate,
  }) : super(key: key);

  @override
  _WeeklyPagerState<T> createState() => _WeeklyPagerState<T>();
}

class _WeeklyPagerState<T> extends State<WeeklyPager<T>> {
  static const _animationDuration = Duration(milliseconds: 400);
  static final dateFormatter = DateFormat.MMMMd();

  final _pageController = PageController();

  final today = LocalDate.today();

  LocalDate initialWeekStart;
  LocalDate initialWeekEnd;

  LocalDate currentWeekStart;
  LocalDate currentWeekEnd;
  T value;

  @override
  void initState() {
    super.initState();

    value = widget.valueChangeNotifier.value;

    currentWeekStart = initialWeekStart = DateUtils.getFirstDayOfWeek(today);
    currentWeekEnd = initialWeekEnd = DateUtils.getLastDayOfWeek(today);

    widget.valueChangeNotifier.addListener(onIndicatorChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            elevation: 1,
            child: _buildDateSelectionSection(),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: changeWeek,
            reverse: true,
            itemBuilder: (context, index) {
              final from = calculateWeekStart(index);
              final to = calculateWeekEnd(index);
              return widget.bodyBuilder(from, to, value);
            },
          ),
        ),
      ],
    );
  }

  void onIndicatorChanged() {
    setState(() {
      value = widget.valueChangeNotifier.value;
    });
  }

  void changeWeek(int index) {
    setState(() {
      currentWeekStart = calculateWeekStart(index);
      currentWeekEnd = calculateWeekEnd(index);
    });
  }

  LocalDate calculateWeekStart(int n) {
    return initialWeekStart.subtractWeeks(n);
  }

  LocalDate calculateWeekEnd(int n) {
    return initialWeekEnd.subtractWeeks(n);
  }

  bool hasNextDateRange() => currentWeekEnd < today;

  bool hasPreviousDateRange() {
    final earliestDate = widget.earliestDate();

    if (earliestDate == null) {
      return true;
    }

    // TODO check this place
    return earliestDate.subtractWeeks(1) <= currentWeekEnd;
    // return !earliestDate.add(const Duration(days: 7)).isAfter(currentWeekEnd);
  }

  void advanceToNextDateRange() {
    _pageController.previousPage(
        duration: _animationDuration, curve: Curves.ease);
  }

  void advanceToPreviousDateRange() {
    _pageController.nextPage(duration: _animationDuration, curve: Curves.ease);
  }

  String _getDateRangeFormatted() {
    return '${dateFormatter.format(currentWeekStart.toDateTimeUnspecified()).capitalizeFirst()} – '
        '${dateFormatter.format(currentWeekEnd.toDateTimeUnspecified()).capitalizeFirst()}';
  }

  Widget _buildDateSelectionSection() {
    return Container(
      color: Theme.of(context).dialogBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed:
                  hasPreviousDateRange() ? advanceToPreviousDateRange : null,
            ),
            Expanded(
              child: Center(
                child: Text(
                  _getDateRangeFormatted(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: hasNextDateRange() ? advanceToNextDateRange : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    widget.valueChangeNotifier.removeListener(onIndicatorChanged);

    super.dispose();
  }
}
