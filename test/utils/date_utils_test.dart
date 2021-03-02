import 'package:nephrogo/utils/date_utils.dart';
import 'package:test/test.dart';
import 'package:time_machine/time_machine.dart';

void main() {
  group('GenerateMonthDates', () {
    test('returns correct dates', () {
      final from = LocalDate(2020, 1, 5);
      final to = LocalDate(2021, 2, 28);
      final dates = DateUtils.generateMonthDates(from, to).toList();

      expect(dates.length, 14);
      expect(dates[0], LocalDate(2020, 1, 1));
      expect(dates[13], LocalDate(2021, 2, 1));
    });
  });
}
