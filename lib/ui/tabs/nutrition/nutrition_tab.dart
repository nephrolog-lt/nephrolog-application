import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/charts/daily_norms_bar_chart.dart';
import 'package:nephrogo/ui/charts/nutrient_weekly_bar_chart.dart';
import 'package:nephrogo/ui/general/app_steam_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo_api_client/model/daily_intakes_light_report.dart';
import 'package:nephrogo_api_client/model/daily_intakes_report.dart';
import 'package:nephrogo_api_client/model/daily_nutrient_norms_with_totals.dart';
import 'package:nephrogo_api_client/model/intake.dart';
import 'package:nephrogo_api_client/model/nutrition_screen_response.dart';
import 'package:nephrogo_api_client/model/nutrition_summary_statistics.dart';

import 'nutrition_calendar.dart';
import 'nutrition_components.dart';
import 'product_search.dart';
import 'summary/nutrition_summary.dart';

class NutritionTab extends StatelessWidget {
  final now = DateTime.now();
  final apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProduct(context),
        label: Text(appLocalizations.createMeals.toUpperCase()),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _buildBody(context),
    );
  }

  Future _createProduct(BuildContext context) {
    return Navigator.pushNamed(
      context,
      Routes.routeProductSearch,
      arguments: ProductSearchScreenArguments(ProductSearchType.choose),
    );
  }

  Widget _buildBody(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return AppStreamBuilder<NutritionScreenResponse>(
      stream: apiService.getNutritionScreenStream(),
      builder: (context, data) {
        final latestIntakes = data.latestIntakes.toList();
        final dailyIntakesReports = data.dailyIntakesReports.toList();
        final todayIntakesReport = data.todayIntakesReport;
        final nutritionSummaryStatistics = data.nutritionSummaryStatistics;

        return Visibility(
          visible: latestIntakes.isNotEmpty,
          replacement: EmptyStateContainer(
            text: appLocalizations.nutritionEmpty,
          ),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 64),
            children: [
              DailyNormsSection(dailyIntakeReport: todayIntakesReport),
              DailyIntakesCard(
                title: appLocalizations.lastMealsSectionTitle,
                intakes: latestIntakes,
                dailyNutrientNormsWithTotals:
                    todayIntakesReport.dailyNutrientNormsAndTotals,
                leading: OutlinedButton(
                  onPressed: () => _openNutritionSummary(
                    context,
                    nutritionSummaryStatistics,
                  ),
                  child: Text(appLocalizations.more.toUpperCase()),
                ),
              ),
              MonthlyNutritionSummarySection(
                data.currentMonthDailyReports.toList(),
                nutritionSummaryStatistics,
              ),
              for (final nutrient in Nutrient.values)
                buildIndicatorChartSection(
                  context,
                  todayIntakesReport,
                  dailyIntakesReports,
                  nutritionSummaryStatistics,
                  nutrient,
                )
            ],
          ),
        );
      },
    );
  }

  Future openWeeklyNutritionScreen(
    BuildContext context,
    NutritionSummaryStatistics nutritionSummaryStatistics,
    Nutrient nutrient,
  ) {
    return Navigator.pushNamed(
      context,
      Routes.routeNutritionSummary,
      arguments: NutritionSummaryScreenArguments(
        nutritionSummaryStatistics: nutritionSummaryStatistics,
        nutrient: nutrient,
        screenType: NutritionSummaryScreenType.weekly,
      ),
    );
  }

  Future _openNutritionSummary(
    BuildContext context,
    NutritionSummaryStatistics nutritionSummaryStatistics,
  ) {
    return Navigator.pushNamed(
      context,
      Routes.routeNutritionSummary,
      arguments: NutritionSummaryScreenArguments(
        screenType: NutritionSummaryScreenType.weekly,
        nutritionSummaryStatistics: nutritionSummaryStatistics,
      ),
    );
  }

  LargeSection buildIndicatorChartSection(
    BuildContext context,
    DailyIntakesReport todayIntakesReport,
    List<DailyIntakesReport> dailyIntakesReports,
    NutritionSummaryStatistics nutritionSummaryStatistics,
    Nutrient nutrient,
  ) {
    final localizations = AppLocalizations.of(context);

    final dailyNormFormatted = todayIntakesReport.dailyNutrientNormsAndTotals
        .getNutrientNormFormatted(nutrient);
    final todayConsumption = todayIntakesReport.dailyNutrientNormsAndTotals
        .getNutrientTotalAmountFormatted(nutrient);

    final showGraph = dailyIntakesReports.expand((e) => e.intakes).isNotEmpty;

    String subtitle;
    if (dailyNormFormatted != null) {
      subtitle = localizations.todayConsumptionWithNorm(
        todayConsumption,
        dailyNormFormatted,
      );
    } else {
      subtitle = localizations.todayConsumptionWithoutNorm(
        todayConsumption,
      );
    }

    return LargeSection(
      title: nutrient.name(localizations),
      subTitle: Text(subtitle),
      trailing: OutlinedButton(
        onPressed: () => openWeeklyNutritionScreen(
          context,
          nutritionSummaryStatistics,
          nutrient,
        ),
        child: Text(localizations.more.toUpperCase()),
      ),
      children: [
        if (showGraph)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: NutrientWeeklyBarChart(
              dailyIntakeReports: dailyIntakesReports,
              nutrient: nutrient,
              maximumDate: todayIntakesReport.date,
              fitInsideVertically: false,
            ),
          )
      ],
    );
  }
}

class DailyNormsSection extends StatelessWidget {
  final DailyIntakesReport dailyIntakeReport;

  const DailyNormsSection({
    Key key,
    @required this.dailyIntakeReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return LargeSection(
      title: appLocalizations.dailyNormsSectionTitle,
      subTitle: Text(appLocalizations.dailyNormsSectionSubtitle),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DailyNormsBarChart(dailyIntakeReport: dailyIntakeReport),
          ],
        ),
      ],
    );
  }
}

class DailyIntakesCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final Widget leading;
  final List<Intake> intakes;
  final DailyNutrientNormsWithTotals dailyNutrientNormsWithTotals;

  const DailyIntakesCard({
    Key key,
    this.title,
    this.subTitle,
    this.leading,
    @required this.intakes,
    @required this.dailyNutrientNormsWithTotals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LargeSection(
      title: title,
      subTitle: subTitle != null ? Text(subTitle) : null,
      trailing: leading,
      showDividers: true,
      children: [
        for (final intake in intakes)
          IntakeExpandableTile(
            intake,
            dailyNutrientNormsWithTotals,
          ),
      ],
    );
  }
}

class MonthlyNutritionSummarySection extends StatelessWidget {
  final List<DailyIntakesLightReport> reports;
  final NutritionSummaryStatistics nutritionSummaryStatistics;
  final _monthFormat = DateFormat('MMMM ');

  MonthlyNutritionSummarySection(
    this.reports,
    this.nutritionSummaryStatistics, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final monthFormatted = _monthFormat.format(DateTime.now());

    return LargeSection(
      title: "$monthFormatted${appLocalizations.summary.toLowerCase()}"
          .capitalizeFirst(),
      subTitle: const NutrientCalendarExplanation(),
      trailing: OutlinedButton(
        onPressed: () => _openNutritionSummary(
          context,
          nutritionSummaryStatistics,
        ),
        child: Text(appLocalizations.more.toUpperCase()),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: NutritionCalendar(
            reports,
            onDaySelected: (_) => _openNutritionSummary(
              context,
              nutritionSummaryStatistics,
            ),
          ),
        ),
      ],
    );
  }

  Future _openNutritionSummary(
    BuildContext context,
    NutritionSummaryStatistics nutritionSummaryStatistics,
  ) {
    return Navigator.pushNamed(
      context,
      Routes.routeNutritionSummary,
      arguments: NutritionSummaryScreenArguments(
        screenType: NutritionSummaryScreenType.monthly,
        nutritionSummaryStatistics: nutritionSummaryStatistics,
      ),
    );
  }
}
