import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo_api_client/model/daily_health_status.dart';
import 'package:nephrogo_api_client/model/daily_intakes_light_report.dart';
import 'package:nephrogo_api_client/model/dialysate_color_enum.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:time_machine/time_machine.dart';

class ManualPeritonealDialysisExcelGenerator {
  static void _writeHeader(
    Worksheet sheet,
    int row,
    AppLocalizations appLocalizations,
  ) {
    sheet.getRangeByIndex(row, 1).setText(appLocalizations.date);
    sheet
        .getRangeByIndex(row, 2)
        .setText('${appLocalizations.dailyBalance}, ml');

    sheet.getRangeByIndex(row, 3).setText(appLocalizations.dialysisStart);
    sheet.getRangeByIndex(row, 4).setText(appLocalizations.dialysisSolution);
    sheet.getRangeByIndex(row, 5).setText('${appLocalizations.balance}, ml');
    sheet
        .getRangeByIndex(row, 6)
        .setText('${appLocalizations.dialysisSolutionIn}, ml');
    sheet
        .getRangeByIndex(row, 7)
        .setText('${appLocalizations.dialysisSolutionOut}, ml');
    sheet.getRangeByIndex(row, 8).setText(appLocalizations.dialysateColor);
    sheet.getRangeByIndex(row, 9).setText(appLocalizations.notes);
    sheet.getRangeByIndex(row, 10).setText(appLocalizations.dialysisEnd);

    sheet.getRangeByIndex(row, 11).setText('${appLocalizations.liquids}, ml');
    sheet.getRangeByIndex(row, 12).setText(
          '${appLocalizations.healthStatusCreationUrine}, '
          '${HealthIndicator.urine.dimension(appLocalizations)}',
        );
    sheet.getRangeByIndex(row, 13).setText(
          '${appLocalizations.weight}, '
          '${HealthIndicator.weight.dimension(appLocalizations)}',
        );

    sheet.getRangeByIndex(row, 14).setText(
          '${appLocalizations.healthStatusCreationBloodPressure}, '
          '${HealthIndicator.bloodPressure.dimension(appLocalizations)}',
        );
    sheet.getRangeByIndex(row, 15).setText(
          '${appLocalizations.pulse}, '
          '${HealthIndicator.pulse.dimension(appLocalizations)}',
        );
    sheet.getRangeByIndex(row, 1, row, 15).cellStyle.bold = true;
  }

  static void _writeDialysis(
    Worksheet sheet,
    int row,
    int startCol,
    ManualPeritonealDialysis dialysis,
    BuildContext context,
    AppLocalizations appLocalizations,
  ) {
    sheet.getRangeByIndex(row, startCol).setText(
          dialysis.startedAt.localDateTime.clockTime.formatHoursAndMinutes(),
        );

    final dialysisSolutionCellStyle = CellStyle(sheet.workbook)
      ..backColor = dialysis.dialysisSolution.color.toHexTriplet()
      ..fontColor = dialysis.dialysisSolution.textColor.toHexTriplet();

    sheet.getRangeByIndex(row, startCol + 1)
      ..setText(dialysis.dialysisSolution.localizedName(appLocalizations))
      ..cellStyle = dialysisSolutionCellStyle;

    sheet
        .getRangeByIndex(row, startCol + 2)
        .setNumber(dialysis.balance.roundToDouble());

    if (dialysis.solutionOutMl != null) {
      sheet
          .getRangeByIndex(row, startCol + 3)
          .setNumber(dialysis.solutionOutMl?.roundToDouble());
    }

    sheet
        .getRangeByIndex(row, startCol + 4)
        .setNumber(dialysis.solutionInMl.roundToDouble());

    if (dialysis.dialysateColor != DialysateColorEnum.unknown) {
      sheet
          .getRangeByIndex(row, startCol + 5)
          .setText(dialysis.dialysateColor.localizedName(appLocalizations));

      if (dialysis.dialysateColor.color != Colors.transparent) {
        sheet.getRangeByIndex(row, startCol + 5).cellStyle
          ..backColor = dialysis.dialysateColor.color.toHexTriplet()
          ..fontColor = dialysis.dialysateColor.textColor.toHexTriplet()
          ..wrapText = true;
      }
    }

    sheet.getRangeByIndex(row, startCol + 6)
      ..setText(dialysis.notes)
      ..cellStyle.wrapText = true;

    if (dialysis.finishedAt != null) {
      final time =
          dialysis.finishedAt.localDateTime.toString('yyyy-MM-dd HH:mm');

      sheet.getRangeByIndex(row, startCol + 7).setText(time);
    }
  }

  static int _writeReport(
    Worksheet sheet,
    int row,
    DailyHealthStatus status,
    Map<LocalDate, int> liquidsMap,
    BuildContext context,
    AppLocalizations appLocalizations,
  ) {
    final date = status.date.calendarDate;
    sheet.getRangeByIndex(row, 1).setText(date.toString('yyyy-MM-dd'));
    sheet
        .getRangeByIndex(row, 2)
        .setNumber(status.totalManualPeritonealDialysisBalance.roundToDouble());

    final sortedDialysis = status.manualPeritonealDialysis
        .sortedBy((d) => d.startedAt.localDateTime, reverse: true)
        .toList();

    final totalDialysis = sortedDialysis.length;

    sortedDialysis.forEachIndexed((i, d) {
      _writeDialysis(sheet, row + i, 3, d, context, appLocalizations);
    });

    const startDailyValuesColumn = 11;

    if (liquidsMap.containsKey(date)) {
      sheet
          .getRangeByIndex(row, startDailyValuesColumn)
          .setNumber(liquidsMap[date].roundToDouble());
    }

    if (status.urineMl != null) {
      sheet
          .getRangeByIndex(row, startDailyValuesColumn + 1)
          .setNumber(status.urineMl.roundToDouble());
    }

    if (status.weightKg != null) {
      sheet
          .getRangeByIndex(row, startDailyValuesColumn + 2)
          .setNumber(status.weightKg);
    }

    final bloodPressures = status.bloodPressures
        .sortedBy((e) => e.measuredAt.localDateTime, reverse: true)
        .map((d) => d.formatAmountWithoutDimensionWithTime(context))
        .join('\n');

    sheet.getRangeByIndex(row, startDailyValuesColumn + 3)
      ..setText(bloodPressures)
      ..columnWidth = 40;

    final pulses = status.pulses
        .sortedBy((e) => e.measuredAt.localDateTime, reverse: true)
        .map((d) => d.formatAmountWithoutDimensionWithTime(context))
        .join('\n');

    sheet.getRangeByIndex(row, startDailyValuesColumn + 4)
      ..setText(pulses)
      ..columnWidth = 30;

    final mergeCols = [
      1,
      2,
      startDailyValuesColumn,
      startDailyValuesColumn + 1,
      startDailyValuesColumn + 2,
      startDailyValuesColumn + 3,
      startDailyValuesColumn + 4
    ];

    for (final col in mergeCols) {
      sheet.getRangeByIndex(row, col, row + totalDialysis - 1).merge();
    }

    return totalDialysis;
  }

  static void _applyGlobalStyle(Worksheet sheet) {
    sheet
        .getRangeByIndex(1, 1, sheet.getLastRow(), sheet.getLastColumn())
        .cellStyle
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center;

    sheet.getRangeByIndex(1, 1, 1, sheet.getLastColumn()).cellStyle.wrapText =
        true;
  }

  static Future<void> _saveAndOpen(Workbook workbook) async {
    final directory = await getApplicationDocumentsDirectory();
    final fullPath = '${directory.path}/rankines-peritorines-dializes.xlsx';

    final bytes = workbook.saveAsStream();
    File(fullPath).writeAsBytes(bytes, flush: true);

    workbook.dispose();

    await OpenFile.open(fullPath);
  }

  static Future<void> generateAndOpenExcel({
    @required BuildContext context,
    @required Iterable<DailyHealthStatus> dailyHealthStatuses,
    @required Iterable<DailyIntakesLightReport> lightDailyIntakeReports,
  }) {
    final workbook = Workbook();

    final sheet = workbook.worksheets[0];
    sheet.name = context.appLocalizations.peritonealDialysisPlural;

    final liquidsMap =
        lightDailyIntakeReports.groupBy((r) => r.date.calendarDate).map(
              (d, r) => MapEntry(
                d,
                r.first.nutrientNormsAndTotals.liquidsMl.total,
              ),
            );

    _writeHeader(sheet, 1, context.appLocalizations);

    final sortedReports = dailyHealthStatuses
        .sortedBy((r) => r.date.calendarDate, reverse: true)
        .toList();

    var writeToRow = 2;
    for (final r in sortedReports) {
      writeToRow += _writeReport(
        sheet,
        writeToRow,
        r,
        liquidsMap,
        context,
        context.appLocalizations,
      );
    }

    for (var colIndex = sheet.getFirstColumn();
        colIndex <= sheet.getLastColumn() - 2;
        ++colIndex) {
      sheet.autoFitColumn(colIndex);
    }

    _applyGlobalStyle(sheet);

    return _saveAndOpen(workbook);
  }
}
