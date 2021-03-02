import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/charts/health_indicator_bar_chart.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/tabs/health_status/blood_pressure_and_pulse_creation_screen.dart';
import 'package:nephrogo_api_client/model/daily_health_status.dart';
import 'package:time_machine/time_machine.dart';

import 'health_status_creation_screen.dart';
import 'health_status_screen.dart';

class HealthStatusCreationFloatingActionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SpeedDialFloatingActionButton(
      label: context.appLocalizations.createHealthStatus,
      children: [
        _createDialButton(
          icon: Icons.analytics,
          onTap: () => _createHealthStatus(context),
          backgroundColor: Colors.teal,
          label: context.appLocalizations.dailyHealthStatusIndicators,
        ),
        _createDialButton(
          icon: Icons.favorite,
          onTap: () => _createBloodPressureOrPulse(context),
          backgroundColor: Colors.deepPurple,
          label: context.appLocalizations.healthStatusCreationBloodPressure,
        ),
        _createDialButton(
          icon: Icons.timeline,
          onTap: () => _createBloodPressureOrPulse(context),
          backgroundColor: Colors.blue,
          label: context.appLocalizations.pulse,
        ),
      ],
    );
  }

  SpeedDialChild _createDialButton({
    @required IconData icon,
    @required Color backgroundColor,
    @required String label,
    @required VoidCallback onTap,
  }) {
    return SpeedDialChild(
      child: Icon(icon),
      backgroundColor: backgroundColor,
      labelStyle: const TextStyle(fontSize: 16),
      foregroundColor: Colors.white,
      label: label,
      onTap: onTap,
    );
  }

  Future _createHealthStatus(BuildContext context) {
    return Navigator.pushNamed(
      context,
      Routes.routeHealthStatusCreation,
      arguments: HealthStatusCreationScreenArguments(),
    );
  }

  Future _createBloodPressureOrPulse(BuildContext context) {
    return Navigator.pushNamed(
      context,
      Routes.routeBloodPressureAndPulseCreation,
      arguments: BloodPressureAndPulseCreationScreenArguments(),
    );
  }
}

class IndicatorChartSection extends StatelessWidget {
  final HealthIndicator indicator;
  final List<DailyHealthStatus> dailyHealthStatuses;
  final bool showAddButton;

  const IndicatorChartSection({
    Key key,
    @required this.indicator,
    @required this.dailyHealthStatuses,
    this.showAddButton = false,
  })  : assert(indicator != null),
        assert(dailyHealthStatuses != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = LocalDate.today();

    final todayHealthStatus = dailyHealthStatuses
        .where((e) => e.date.calendarDate == today)
        .firstOrNull();

    final todayConsumption = todayHealthStatus?.getHealthIndicatorFormatted(
          indicator,
          context.appLocalizations,
        ) ??
        context.appLocalizations.noInfo.toLowerCase();

    final hasReports =
        dailyHealthStatuses.any((s) => s.isIndicatorExists(indicator));

    final title = indicator.name(context.appLocalizations);
    final subtitle =
        context.appLocalizations.healthIndicatorSubtitle(todayConsumption);

    return LargeSection(
      title: Text(title),
      showDividers: true,
      subtitle: Text(subtitle),
      trailing: OutlinedButton(
        onPressed: () => _openWeeklyHealthIndicatorScreen(context, indicator),
        child: Text(context.appLocalizations.more.toUpperCase()),
      ),
      children: [
        if (hasReports)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: HealthIndicatorBarChart(
              dailyHealthStatuses: dailyHealthStatuses,
              indicator: indicator,
              from: today.subtractDays(6),
              to: today,
            ),
          ),
        if (showAddButton) _buildAddButton(context)
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final text = _getAddButtonText(context.appLocalizations).toUpperCase();
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _openAddIndicator(context),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            text,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _openAddIndicator(BuildContext context) {
    switch (indicator) {
      case HealthIndicator.bloodPressure:
      case HealthIndicator.pulse:
        return _createBloodPressureOrPulse(context);
      default:
        return _createHealthStatus(context);
    }
  }

  String _getAddButtonText(AppLocalizations appLocalizations) {
    switch (indicator) {
      case HealthIndicator.bloodPressure:
        return appLocalizations.createBloodPressure;
      case HealthIndicator.pulse:
        return appLocalizations.createPulse;
      case HealthIndicator.weight:
        return appLocalizations.createWeight;
      case HealthIndicator.urine:
        return appLocalizations.createUrine;
      default:
        throw ArgumentError.value(indicator);
    }
  }

  Future<void> _createHealthStatus(BuildContext context) {
    return Navigator.pushNamed(
      context,
      Routes.routeHealthStatusCreation,
      arguments: HealthStatusCreationScreenArguments(),
    );
  }

  Future<void> _createBloodPressureOrPulse(BuildContext context) {
    return Navigator.pushNamed(
      context,
      Routes.routeBloodPressureAndPulseCreation,
      arguments: BloodPressureAndPulseCreationScreenArguments(),
    );
  }

  Future<void> _openWeeklyHealthIndicatorScreen(
    BuildContext context,
    HealthIndicator indicator,
  ) {
    return Navigator.pushNamed(
      context,
      Routes.routeHealthStatusScreen,
      arguments: HealthStatusScreenArguments(indicator),
    );
  }
}
