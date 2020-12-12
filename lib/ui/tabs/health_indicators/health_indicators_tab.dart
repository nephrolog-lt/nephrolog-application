import 'package:flutter/material.dart';
import 'package:nephrolog/models/contract.dart';
import 'package:nephrolog/routes.dart';
import 'package:nephrolog/services/api_service.dart';
import 'package:nephrolog/ui/charts/health_indicator_bar_chart.dart';
import 'package:nephrolog/ui/general/app_future_builder.dart';
import 'package:nephrolog/extensions/date_extensions.dart';
import 'package:nephrolog/ui/general/components.dart';
import 'package:nephrolog/ui/tabs/health_indicators/weekly_health_indicators_screen.dart';
import 'package:nephrolog/extensions/contract_extensions.dart';

class HealthIndicatorsTab extends StatelessWidget {
  final ValueNotifier<int> valueNotifier = ValueNotifier(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          Routes.ROUTE_HEALTH_INDICATORS_CREATION,
        ),
        label: Text("PRIDĖTI RODIKLIUS"),
        icon: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: HealthIndicatorsTabBody(),
    );
  }
}

class HealthIndicatorsTabBody extends StatelessWidget {
  final apiService = ApiService();
  final now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final weekStartEnd = now.startAndEndOfWeek();

    final from = weekStartEnd.item1;
    final to = weekStartEnd.item2;

    return AppFutureBuilder<UserHealthStatusResponse>(
      future: apiService.getUserHealthStatus(from, to),
      builder: (BuildContext context, UserHealthStatusResponse response) {
        final sections = HealthIndicator.values
            .map((i) => buildIndicatorChartSection(
                context, response.dailyHealthStatuses, i))
            .toList();

        return ListView(
          padding: EdgeInsets.only(bottom: 64),
          children: sections,
        );
      },
    );
  }

  void openWeeklyHealthIndicatorScreen(
    BuildContext context,
    HealthIndicator indicator,
  ) {
    Navigator.pushNamed(
      context,
      Routes.ROUTE_WEEKLY_HEALTH_INDICATORS_SCREEN,
      arguments: WeeklyHealthIndicatorsScreenArguments(indicator),
    );
  }

  LargeSection buildIndicatorChartSection(
    BuildContext context,
    List<DailyHealthStatus> dailyHealthStatuses,
    HealthIndicator indicator,
  ) {
    final todayConsumption =
        dailyHealthStatuses.first.getHealthIndicatorFormatted(indicator) ??
            "nėra informacijos";

    return LargeSection(
      title: indicator.name,
      subTitle: "Šiandien: $todayConsumption",
      children: [
        HealthIndicatorBarChart(
          dailyHealthStatuses: dailyHealthStatuses,
          indicator: indicator,
        ),
      ],
      leading: OutlineButton(
        child: Text("DAUGIAU"),
        onPressed: () => openWeeklyHealthIndicatorScreen(context, indicator),
      ),
    );
  }
}
