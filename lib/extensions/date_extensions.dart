import 'package:time_machine/time_machine.dart';

extension LocalTimeExtensuons on LocalTime {
  String formatHoursAndMinutes() {
    return toString('HH:mm');
  }
}

extension OffsetDateTimeExtensions on OffsetDateTime {
  LocalDate get localZoneCalendarDate {
    return inLocalZone.calendarDate;
  }

  ZonedDateTime get inLocalZone => inZone(DateTimeZone.local);

  OffsetTime toOffsetTimeInLocalZone() {
    return inLocalZone.toOffsetDateTime().toOffsetTime();
  }

  OffsetDateTime adjustLocalZoneDate(LocalDate Function(LocalDate) adjuster) {
    return inLocalZone.localDateTime.adjustDate(adjuster).withOffset(offset);
  }

  OffsetDateTime adjustLocalZoneTime(LocalTime Function(LocalTime) adjuster) {
    return inLocalZone.localDateTime.adjustTime(adjuster).withOffset(offset);
  }
}
