import 'package:time_machine/time_machine.dart';

class DateUtils {
  DateUtils._();

  static Iterable<LocalDate> generateDates(
    LocalDate startDate,
    LocalDate endDate,
  ) sync* {
    for (var date = startDate; date <= endDate; date = date.addDays(1)) {
      yield date;
    }
  }

  static Iterable<LocalDate> generateWeekDates(
    LocalDate startDate,
    LocalDate endDate,
  ) sync* {
    for (var date = getFirstDayOfWeek(startDate);
        date <= endDate;
        date = date.addWeeks(1)) {
      yield date;
    }
  }

  static Iterable<LocalDate> generateMonthDates(
    LocalDate startDate,
    LocalDate endDate,
  ) sync* {
    final adjustedStartDate = getFirstDayOfMonth(startDate);
    final adjustedEndDate = getFirstDayOfMonth(endDate);

    for (var date = adjustedStartDate;
        date <= adjustedEndDate;
        date = date.addMonths(1)) {
      yield date;
    }
  }

  static LocalDate getFirstDayOfWeek(LocalDate date) {
    return date.subtractDays(
      date.dayOfWeek.value - DayOfWeek.monday.value,
    );
  }

  static LocalDate getLastDayOfWeek(LocalDate date) {
    return date.addDays(
      DayOfWeek.sunday.value - date.dayOfWeek.value,
    );
  }

  static LocalDate getFirstDayOfMonth(LocalDate date) {
    return LocalDate(date.year, date.monthOfYear, 1);
  }

  static LocalDate getLastDayOfCurrentMonth(LocalDate date) {
    return getFirstDayOfMonth(date).addMonths(1).subtractDays(1);
  }
}
