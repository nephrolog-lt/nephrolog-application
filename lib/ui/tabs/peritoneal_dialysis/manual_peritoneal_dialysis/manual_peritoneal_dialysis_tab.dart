import 'package:flutter/material.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/general/app_steam_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/tabs/health_status/health_status_components.dart';
import 'package:nephrogo/ui/tabs/nutrition/nutrition_components.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis_screen_response.dart';
import 'package:time_machine/time_machine.dart';

import 'manual_peritoneal_dialysis_creation_screen.dart';
import 'manual_peritoneal_dialysis_screen.dart';

class ManualPeritonealDialysisTab extends StatelessWidget {
  final apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return AppStreamBuilder<ManualPeritonealDialysisScreenResponse>(
      stream: apiService.getManualPeritonealDialysisScreenStream(),
      builder: (context, response) {
        return _ManualPeritonealDialysisTabBody(response: response);
      },
    );
  }
}

class _ManualPeritonealDialysisTabBody extends StatelessWidget {
  static final indicators = [
    HealthIndicator.bloodPressure,
    HealthIndicator.pulse,
    HealthIndicator.weight,
    HealthIndicator.urine,
  ];

  final ManualPeritonealDialysisScreenResponse response;

  const _ManualPeritonealDialysisTabBody({Key key, @required this.response})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SpeedDialFloatingActionButton(
        label: _getCreateButtonLabel(context),
        icon: response.peritonealDialysisInProgress == null
            ? Icons.add
            : Icons.play_arrow,
        onPress: () => _openDialysisCreation(context),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (response.lastPeritonealDialysis.isEmpty) {
      return EmptyStateContainer(
        text: context.appLocalizations.manualPeritonealDialysisEmpty,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 64),
      children: [
        _buildTotalBalanceSection(context),
        NutrientChartSection(
          reports: response.lastWeekLightNutritionReports.toList(),
          nutrient: Nutrient.liquids,
        ),
        for (final indicator in indicators)
          IndicatorChartSection(
            indicator: indicator,
            dailyHealthStatuses: response.lastWeekHealthStatuses.toList(),
            showAddButton: true,
          )
      ],
    );
  }

  String _getCreateButtonLabel(BuildContext context) {
    if (response.peritonealDialysisInProgress == null) {
      return context.appLocalizations.startDialysis;
    }

    return context.appLocalizations.continueDialysis;
  }

  Widget _buildTotalBalanceSection(BuildContext context) {
    final today = LocalDate.today();

    final healthStatusesWithDialysis = response.lastWeekHealthStatuses
        .where((s) => s.manualPeritonealDialysis.isNotEmpty)
        .toList();

    final todayDialysis = healthStatusesWithDialysis
        .where((r) => r.date.calendarDate == today)
        .firstOrNull();

    final todayFormatted =
        todayDialysis?.totalManualPeritonealDialysisBalanceFormatted ?? '—';

    final subtitle =
        '${context.appLocalizations.todayBalance}: $todayFormatted';

    final initialDate = response.lastPeritonealDialysis
            .map((d) => d.startedAt.calendarDate)
            .maxBy((_, d) => d) ??
        today;

    return LargeSection(
      title: Text(context.appLocalizations.peritonealDialysisPlural),
      showDividers: true,
      subtitle: Text(subtitle),
      trailing: OutlinedButton(
        onPressed: () => Navigator.of(context).pushNamed(
          Routes.routeManualPeritonealDialysisScreen,
          arguments: ManualPeritonealDialysisScreenArguments(
            initialDate: initialDate,
          ),
        ),
        child: Text(context.appLocalizations.more.toUpperCase()),
      ),
      children: [
        for (final dialysis in response.lastPeritonealDialysis)
          ManualPeritonealDialysisTile(dialysis)
      ],
    );
  }

  Future<void> _openDialysisCreation(BuildContext context) {
    return Navigator.of(context).pushNamed(
      Routes.routeManualPeritonealDialysisCreation,
      arguments: ManualPeritonealDialysisCreationScreenArguments(
        response.peritonealDialysisInProgress,
      ),
    );
  }
}
