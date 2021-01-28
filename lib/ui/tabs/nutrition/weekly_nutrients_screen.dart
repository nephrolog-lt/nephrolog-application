import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/charts/nutrient_weekly_bar_chart.dart';
import 'package:nephrogo/ui/general/app_steam_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/general/weekly_pager.dart';
import 'package:nephrogo_api_client/model/daily_intakes_report.dart';
import 'package:nephrogo_api_client/model/intake.dart';
import 'package:nephrogo_api_client/model/nutrient_weekly_screen_response.dart';

import 'intake_create.dart';

class WeeklyNutrientsScreenArguments {
  final Nutrient nutrient;

  WeeklyNutrientsScreenArguments(this.nutrient);
}

class WeeklyNutrientsScreen extends StatefulWidget {
  final Nutrient nutrient;

  const WeeklyNutrientsScreen({Key key, @required this.nutrient})
      : super(key: key);

  @override
  _WeeklyNutrientsScreenState createState() => _WeeklyNutrientsScreenState();
}

class _WeeklyNutrientsScreenState extends State<WeeklyNutrientsScreen> {
  final _apiService = ApiService();

  AppLocalizations _appLocalizations;

  ValueNotifier<Nutrient> _nutrientChangeNotifier;
  DateTime _earliestDate;

  @override
  void initState() {
    super.initState();

    _nutrientChangeNotifier = ValueNotifier<Nutrient>(widget.nutrient);
  }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIndicatorSelectionPopupMenu(context),
        label: Text(_appLocalizations.nutrientShort.toUpperCase()),
        icon: Icon(Icons.swap_horizontal_circle),
      ),
      body: WeeklyPager<Nutrient>(
        valueChangeNotifier: _nutrientChangeNotifier,
        earliestDate: () => _earliestDate,
        bodyBuilder: (from, to, nutrient) {
          return AppStreamBuilder<NutrientWeeklyScreenResponse>(
            stream: _apiService.getWeeklyDailyIntakesReportStream(from, to),
            builder: (context, data) {
              _earliestDate = data.earliestReportDate;

              return _WeeklyNutrientsComponent(
                nutrient: nutrient,
                weekStart: from,
                weekEnd: to,
                dailyIntakesReports: data.dailyIntakesReports.toList(),
              );
            },
          );
        },
      ),
    );
  }

  String _getTitle() {
    switch (_nutrientChangeNotifier.value) {
      case Nutrient.energy:
        return _appLocalizations.consumptionEnergy;
      case Nutrient.liquids:
        return _appLocalizations.consumptionLiquids;
      case Nutrient.proteins:
        return _appLocalizations.consumptionLiquids;
      case Nutrient.sodium:
        return _appLocalizations.consumptionSodium;
      case Nutrient.potassium:
        return _appLocalizations.consumptionPotassium;
      case Nutrient.phosphorus:
        return _appLocalizations.consumptionPhosphorus;
      default:
        throw ArgumentError.value(
            this, 'type', 'Unable to map indicator to name');
    }
  }

  void _changeNutrient(Nutrient nutrient) {
    setState(() {
      _nutrientChangeNotifier.value = nutrient;
    });
  }

  Future _showIndicatorSelectionPopupMenu(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context);

    final options = Nutrient.values.map((t) {
      return SimpleDialogOption(
        child: Text(t.name(appLocalizations)),
        onPressed: () => Navigator.pop(context, t),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      );
    }).toList();

    final selectedType = await showDialog<Nutrient>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(appLocalizations.chooseNutrient),
          children: options,
        );
      },
    );

    if (selectedType != null) {
      _changeNutrient(selectedType);
    }
  }

  @override
  void dispose() {
    _nutrientChangeNotifier.dispose();

    super.dispose();
  }
}

class _WeeklyNutrientsComponent extends StatelessWidget {
  final List<DailyIntakesReport> dailyIntakesReports;
  final Nutrient nutrient;

  final DateTime weekStart;
  final DateTime weekEnd;

  const _WeeklyNutrientsComponent({
    Key key,
    @required this.nutrient,
    @required this.weekStart,
    @required this.weekEnd,
    @required this.dailyIntakesReports,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasIntakes =
        dailyIntakesReports.expand((di) => di.intakes).isNotEmpty;

    final dailyIntakeReportsWithIntakesSorted = dailyIntakesReports
        .where((di) => di.intakes.isNotEmpty)
        .sortedBy((e) => e.date, reverse: true);

    return Visibility(
      visible: hasIntakes,
      replacement: EmptyStateContainer(
        text: AppLocalizations.of(context).weeklyNutrientsEmpty,
      ),
      child: ListView(
        padding: EdgeInsets.only(bottom: 64),
        children: [
          BasicSection(
            children: [
              NutrientWeeklyBarChart(
                dailyIntakeReports: dailyIntakesReports,
                nutrient: nutrient,
                maximumDate: weekEnd,
                fitInsideVertically: true,
              ),
            ],
          ),
          for (final dailyIntakesReport in dailyIntakeReportsWithIntakesSorted)
            DailyIntakeSection(
              nutrient: nutrient,
              dailyIntakesReport: dailyIntakesReport,
            )
        ],
      ),
    );
  }
}

class DailyIntakeSection extends StatelessWidget {
  static final _dateFormat = DateFormat('EEEE, d');

  final Nutrient nutrient;
  final DailyIntakesReport dailyIntakesReport;

  DailyIntakeSection({
    Key key,
    @required this.nutrient,
    @required this.dailyIntakesReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final consumption =
        dailyIntakesReport.getDailyNutrientConsumption(nutrient);
    final dailyNormFormatted =
        dailyIntakesReport.getNutrientNormFormatted(nutrient);
    final totalFormatted =
        dailyIntakesReport.getNutrientTotalAmountFormatted(nutrient);
    final intakesSorted =
        dailyIntakesReport.intakes.sortedBy((e) => e.consumedAt, reverse: true);

    double ratio;

    if (consumption.norm != null) {
      ratio = consumption.total.toDouble() / consumption.norm;
    }

    return LargeSection(
      title:
          _dateFormat.format(dailyIntakesReport.date).capitalizeFirst() + ' d.',
      leading: ratio != null ? _getVisualIndicator(ratio) : null,
      subTitle:
          getSubtitle(appLocalizations, totalFormatted, dailyNormFormatted),
      children: [
        for (final intake in intakesSorted)
          IndicatorIntakeTile(intake: intake, nutrient: nutrient)
      ],
    );
  }

  String getSubtitle(AppLocalizations appLocalizations, String totalFormatted,
      String dailyNormFormatted) {
    final nutrientName = nutrient.name(appLocalizations);

    if (dailyNormFormatted == null) {
      return appLocalizations.consumptionWithNutrientWithoutNorm(
        nutrientName,
        totalFormatted,
      );
    }

    return appLocalizations.consumptionWithNutrient(
      nutrientName,
      totalFormatted,
      dailyNormFormatted,
    );
  }

  Widget _getVisualIndicator(double percent) {
    return Container(
      width: 70.0,
      height: 70.0,
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          color: percent > 1.0 ? Colors.redAccent : Colors.teal,
          shape: BoxShape.circle),
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 4.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        Text(
          '${(percent * 100).round()}%',
          style: TextStyle(
            fontSize: 13.0,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}

class IndicatorIntakeTile extends StatelessWidget {
  static final dateFormat = DateFormat('MMMM d HH:mm');

  final Intake intake;
  final Nutrient nutrient;

  const IndicatorIntakeTile({
    Key key,
    this.intake,
    this.nutrient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = intake.product;

    final dateFormatted =
        dateFormat.format(intake.consumedAt.toLocal()).capitalizeFirst();

    return AppListTile(
      key: Key('IndicatorIntakeTile-$nutrient-${intake.id}'),
      title: Text(product.name),
      contentPadding: EdgeInsets.zero,
      subtitle: Text('${intake.getAmountFormatted()} | $dateFormatted'),
      leading: ProductKindIcon(productKind: product.productKind),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(intake.getNutrientAmountFormatted(nutrient)),
          ),
          Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(
        Routes.ROUTE_INTAKE_CREATE,
        arguments: IntakeCreateScreenArguments(intake: intake),
      ),
    );
  }
}
