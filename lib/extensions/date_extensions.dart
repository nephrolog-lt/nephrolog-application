import 'package:time_machine/time_machine.dart';

extension LocalTimeExtensuons on LocalTime {
  String formatHoursAndMinutes() {
    return toString('HH:mm');
  }
}
