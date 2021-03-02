import 'package:collection_ext/all.dart';
import 'package:collection_ext/iterables.dart';
import 'package:flutter/material.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/constants.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/charts/daily_meal_type_consumption_column_series.dart';
import 'package:nephrogo/ui/charts/daily_norms_bar_chart.dart';
import 'package:nephrogo/ui/general/app_steam_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/general/period_pager.dart';
import 'package:nephrogo/ui/tabs/nutrition/nutrition_components.dart';
import 'package:nephrogo/ui/tabs/nutrition/product_search.dart';
import 'package:nephrogo_api_client/model/daily_intakes_report.dart';
import 'package:nephrogo_api_client/model/daily_intakes_report_response.dart';
import 'package:nephrogo_api_client/model/daily_nutrient_norms_with_totals.dart';
import 'package:nephrogo_api_client/model/intake.dart';
import 'package:nephrogo_api_client/model/meal_type_enum.dart';
import 'package:time_machine/time_machine.dart';

import 'nutrition_summary_components.dart';

class NutritionDailySummaryScreenArguments {
  final LocalDate date;
  final Nutrient nutrient;

  NutritionDailySummaryScreenArguments(this.date, {this.nutrient});
}

class NutritionDailySummaryScreen extends StatefulWidget {
  final LocalDate date;
  final Nutrient nutrient;

  const NutritionDailySummaryScreen(
    this.date, {
    Key key,
    @required this.nutrient,
  })  : assert(date != null),
        super(key: key);

  @override
  _NutritionDailySummaryScreenState createState() =>
      _NutritionDailySummaryScreenState();
}

class _NutritionDailySummaryScreenState
    extends State<NutritionDailySummaryScreen> {
  final _apiService = ApiService();

  LocalDate date;

  @override
  void initState() {
    super.initState();

    date = widget.date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          TextButton(
            onPressed: () => _openGeneralRecommendations(),
            child: Text(
              appLocalizations.tips.toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: DailyPager(
        earliestDate: Constants.earliestDate,
        initialDate: date,
        onPageChanged: (from, to) {
          date = from;
        },
        bodyBuilder: (context, header, from, to) {
          return AppStreamBuilder<DailyIntakesReportResponse>(
            stream: _apiService.getDailyIntakesReportStream(from),
            builder: (context, data) {
              final report = data?.dailyIntakesReport;

              if (report == null || report.intakes.isEmpty) {
                return NutritionDailyListWithHeaderEmpty(
                  header: header,
                  date: from,
                );
              }

              if (widget.nutrient != null) {
                return _DailyNutritionNutrientList(
                  report,
                  widget.nutrient,
                  header: header,
                );
              }

              return _NutritionDailySummaryList(
                report,
                header: header,
              );
            },
          );
        },
      ),
    );
  }

  String _getTitle() {
    if (widget.nutrient == null) {
      return appLocalizations.dailyNutritionSummary;
    }

    return widget.nutrient.consumptionName(appLocalizations);
  }

  Future _openGeneralRecommendations() {
    return Navigator.pushNamed(context, Routes.routeGeneralRecommendations);
  }
}

class _NutritionDailySummaryList extends StatelessWidget {
  final DailyIntakesReport dailyIntakesReport;
  final Widget header;

  const _NutritionDailySummaryList(
    this.dailyIntakesReport, {
    Key key,
    @required this.header,
  })  : assert(header != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final norms = dailyIntakesReport.dailyNutrientNormsAndTotals;

    final groupedIntakes =
        dailyIntakesReport.getIntakesGroupedByMealType().toList();

    return ListView.builder(
      itemCount: groupedIntakes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return DateSwitcherHeaderSection(
            header: header,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: DailyNormsBarChart(
                  dailyIntakeReport: dailyIntakesReport.toLightReport(),
                ),
              ),
            ],
          );
        }
        final group = groupedIntakes[index - 1];

        return _NutritionDailySummaryListNutritionSection(
          mealType: group.item1,
          intakes: group.item2,
          date: dailyIntakesReport.date.calendarDate,
          norms: norms,
        );
      },
    );
  }
}

class _NutritionDailySummaryListNutritionSection extends StatelessWidget {
  final MealTypeEnum mealType;
  final List<Intake> intakes;
  final DailyNutrientNormsWithTotals norms;
  final LocalDate date;

  const _NutritionDailySummaryListNutritionSection({
    Key key,
    @required this.mealType,
    @required this.intakes,
    @required this.date,
    @required this.norms,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LargeSection(
      showDividers: true,
      title: Text(mealType.localizedName(context.appLocalizations)),
      trailing: mealType != MealTypeEnum.unknown
          ? OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                Routes.routeProductSearch,
                arguments: ProductSearchScreenArguments(
                  ProductSearchType.choose,
                  mealType,
                  date: date,
                ),
              ),
              child: Text(context.appLocalizations.create.toUpperCase()),
            )
          : null,
      children: [
        for (final intake in intakes)
          IntakeWithNormsSection(
            intake,
            norms,
            margin: EdgeInsets.zero,
          )
      ],
    );
  }
}

class _DailyNutritionNutrientList extends StatelessWidget {
  final Widget header;
  final DailyIntakesReport dailyIntakesReport;
  final Nutrient nutrient;

  const _DailyNutritionNutrientList(
    this.dailyIntakesReport,
    this.nutrient, {
    Key key,
    @required this.header,
  })  : assert(header != null),
        assert(dailyIntakesReport != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final groupedIntakes =
        dailyIntakesReport.getIntakesGroupedByMealType().toList();

    return ListView.builder(
      itemCount: groupedIntakes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return DateSwitcherHeaderSection(
            header: header,
            children: [
              DailyMealTypeConsumptionColumnSeries(
                report: dailyIntakesReport,
                nutrient: nutrient,
              ),
            ],
          );
        }

        final group = groupedIntakes[index - 1];

        return _DailyNutritionNutrientSection(
          nutrient: nutrient,
          mealType: group.item1,
          intakes: group.item2,
          dailyIntakesReport: dailyIntakesReport,
        );
      },
    );
  }
}

class _DailyNutritionNutrientSection extends StatelessWidget {
  final Nutrient nutrient;

  final MealTypeEnum mealType;
  final List<Intake> intakes;
  final DailyIntakesReport dailyIntakesReport;

  const _DailyNutritionNutrientSection({
    Key key,
    @required this.nutrient,
    @required this.mealType,
    @required this.intakes,
    @required this.dailyIntakesReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LargeSection(
      showDividers: true,
      showHeaderDivider: true,
      title: Text(mealType.localizedName(context.appLocalizations)),
      subtitle: intakes?.isNotEmpty ?? false
          ? Text(_getMealTotalText(context))
          : null,
      trailing: mealType != MealTypeEnum.unknown
          ? OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                Routes.routeProductSearch,
                arguments: ProductSearchScreenArguments(
                  ProductSearchType.choose,
                  mealType,
                  date: dailyIntakesReport.date.calendarDate,
                ),
              ),
              child: Text(context.appLocalizations.create.toUpperCase()),
            )
          : null,
      children: [
        for (final intake in intakes)
          NutrientIntakeTile(
            intake,
            nutrient,
            dailyIntakesReport.dailyNutrientNormsAndTotals,
          )
      ],
    );
  }

  String _getMealTotalText(BuildContext context) {
    final total = intakes.sumBy((i, e) => e.getNutrientAmount(nutrient));
    final formattedAmount = nutrient.formatAmount(total);

    return context.appLocalizations.consumptionWithoutNorm(formattedAmount);
  }
}
