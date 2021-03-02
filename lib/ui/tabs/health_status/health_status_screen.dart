import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/constants.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/charts/health_indicator_bar_chart.dart';
import 'package:nephrogo/ui/general/app_steam_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/general/period_pager.dart';
import 'package:nephrogo/ui/tabs/health_status/blood_pressure_edit_screen.dart';
import 'package:nephrogo/ui/tabs/health_status/health_status_creation_screen.dart';
import 'package:nephrogo/ui/tabs/health_status/pulse_edit_screen.dart';
import 'package:nephrogo/ui/tabs/nutrition/summary/nutrition_summary_components.dart';
import 'package:nephrogo_api_client/model/daily_health_status.dart';
import 'package:nephrogo_api_client/model/health_status_weekly_screen_response.dart';
import 'package:time_machine/time_machine.dart';

import 'blood_pressure_and_pulse_creation_screen.dart';

class HealthStatusScreenArguments {
  final HealthIndicator healthIndicator;

  const HealthStatusScreenArguments(this.healthIndicator);
}

class HealthStatusScreen extends StatefulWidget {
  final HealthIndicator healthIndicator;

  const HealthStatusScreen({Key key, @required this.healthIndicator})
      : super(key: key);

  @override
  _HealthStatusScreenState createState() => _HealthStatusScreenState();
}

class _HealthStatusScreenState extends State<HealthStatusScreen> {
  bool get _isDailyTabAvailable => widget.healthIndicator.isMultiValuesPerDay;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _isDailyTabAvailable ? 3 : 2,
      initialIndex: _isDailyTabAvailable ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tabTitle),
          bottom: TabBar(
            tabs: [
              if (_isDailyTabAvailable)
                Tab(text: appLocalizations.daily.toUpperCase()),
              Tab(text: appLocalizations.weekly.toUpperCase()),
              Tab(text: appLocalizations.monthly.toUpperCase()),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (_isDailyTabAvailable)
              _HealthStatusScreenTab(
                healthIndicator: widget.healthIndicator,
                pagerType: PeriodPagerType.daily,
              ),
            _HealthStatusScreenTab(
              healthIndicator: widget.healthIndicator,
              pagerType: PeriodPagerType.weekly,
            ),
            _HealthStatusScreenTab(
              healthIndicator: widget.healthIndicator,
              pagerType: PeriodPagerType.monthly,
            ),
          ],
        ),
      ),
    );
  }

  String get _tabTitle {
    return widget.healthIndicator.name(appLocalizations);
  }
}

class _HealthStatusScreenTab extends StatelessWidget {
  final HealthIndicator healthIndicator;

  final ApiService _apiService = ApiService();
  final PeriodPagerType pagerType;

  _HealthStatusScreenTab({
    Key key,
    @required this.healthIndicator,
    @required this.pagerType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PeriodPager(
      pagerType: pagerType,
      initialDate: LocalDate.today(),
      earliestDate: Constants.earliestDate,
      bodyBuilder: _bodyBuilder,
    );
  }

  Widget _bodyBuilder(
    BuildContext context,
    Widget header,
    LocalDate from,
    LocalDate to,
  ) {
    return AppStreamBuilder<HealthStatusWeeklyScreenResponse>(
      stream: _apiService.getHealthStatusesStream(from, to),
      builder: (context, data) {
        final indicatorsExists = data.dailyHealthStatuses
            .any((s) => s.isIndicatorExists(healthIndicator));

        if (!indicatorsExists) {
          if (pagerType == PeriodPagerType.daily) {
            return EmptyDailyHealthIndicatorsListWithChart(
              date: from,
              healthIndicator: healthIndicator,
              header: header,
            );
          } else {
            return DateSwitcherHeaderSection(
              header: header,
              children: [
                EmptyStateContainer(
                  text: context.appLocalizations.weeklyHealthStatusEmpty,
                )
              ],
            );
          }
        }

        return HealthIndicatorsListWithChart(
          dailyHealthStatuses: data.dailyHealthStatuses.toList(),
          header: header,
          healthIndicator: healthIndicator,
          from: from,
          to: to,
          appLocalizations: context.appLocalizations,
        );
      },
    );
  }
}

class EmptyDailyHealthIndicatorsListWithChart extends StatelessWidget {
  final LocalDate date;
  final HealthIndicator healthIndicator;
  final Widget header;

  const EmptyDailyHealthIndicatorsListWithChart({
    Key key,
    @required this.date,
    @required this.healthIndicator,
    @required this.header,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        DateSwitcherHeaderSection(
          header: header,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: HealthIndicatorBarChart(
                dailyHealthStatuses: const [],
                indicator: healthIndicator,
                from: date,
                to: date,
              ),
            ),
          ],
        ),
        DailyHealthStatusIndicatorMultiValueSection(
          date: date,
          indicator: healthIndicator,
          children: const [],
        ),
      ],
    );
  }
}

class HealthIndicatorsListWithChart extends StatelessWidget {
  final HealthIndicator healthIndicator;
  final List<DailyHealthStatus> dailyHealthStatuses;
  final AppLocalizations appLocalizations;
  final LocalDate from;
  final LocalDate to;
  final Widget header;

  const HealthIndicatorsListWithChart({
    Key key,
    @required this.dailyHealthStatuses,
    @required this.healthIndicator,
    @required this.appLocalizations,
    @required this.from,
    @required this.to,
    @required this.header,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedHealthStatusesWithIndicators = dailyHealthStatuses
        .where((dhs) => dhs.isIndicatorExists(healthIndicator))
        .sortedBy((e) => e.date.calendarDate, reverse: true)
        .toList();

    return ListView.builder(
      itemCount: sortedHealthStatusesWithIndicators.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return DateSwitcherHeaderSection(
            header: header,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: HealthIndicatorBarChart(
                  dailyHealthStatuses: dailyHealthStatuses,
                  indicator: healthIndicator,
                  from: from,
                  to: to,
                ),
              ),
            ],
          );
        }

        final dailyHealthStatus = sortedHealthStatusesWithIndicators[index - 1];

        return _buildSection(dailyHealthStatus);
      },
    );
  }

  Widget _buildSection(DailyHealthStatus dailyHealthStatus) {
    if (healthIndicator.isMultiValuesPerDay) {
      return DailyHealthStatusIndicatorMultiValueSectionWithTiles(
        dailyHealthStatus: dailyHealthStatus,
        indicator: healthIndicator,
      );
    }

    return BasicSection(
      children: [
        DailyHealthStatusIndicatorTile(
          dailyHealthStatus: dailyHealthStatus,
          indicator: healthIndicator,
        )
      ],
    );
  }
}

class DailyHealthStatusIndicatorMultiValueSection extends StatelessWidget {
  final dateFormat = DateFormat('EEEE, MMMM d');

  final LocalDate date;
  final HealthIndicator indicator;
  final List<Widget> children;

  DailyHealthStatusIndicatorMultiValueSection({
    Key key,
    @required this.date,
    @required this.indicator,
    @required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasicSection(
      header: AppListTile(
        title: Text(
          dateFormat.format(date.toDateTimeUnspecified()).capitalizeFirst(),
          maxLines: 1,
        ),
        subtitle: Text(indicator.name(context.appLocalizations)),
        trailing: OutlinedButton(
          onPressed: () => Navigator.pushNamed(
            context,
            Routes.routeBloodPressureAndPulseCreation,
            arguments: BloodPressureAndPulseCreationScreenArguments(
              date: date,
            ),
          ),
          child: Text(context.appLocalizations.create.toUpperCase()),
        ),
      ),
      showDividers: true,
      showHeaderDivider: true,
      children: children,
    );
  }
}

class DailyHealthStatusIndicatorMultiValueSectionWithTiles
    extends StatelessWidget {
  final fullDateFormat = DateFormat.MMMMd().add_jm();

  final DailyHealthStatus dailyHealthStatus;
  final HealthIndicator indicator;

  DailyHealthStatusIndicatorMultiValueSectionWithTiles({
    Key key,
    @required this.dailyHealthStatus,
    @required this.indicator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DailyHealthStatusIndicatorMultiValueSection(
      date: dailyHealthStatus.date.calendarDate,
      indicator: indicator,
      children: _buildChildren(context).toList(),
    );
  }

  Widget _buildValueTile({
    @required LocalDateTime dateTime,
    @required String formattedAmount,
    @required GestureTapCallback onTap,
  }) {
    return AppListTile(
      title: Text(fullDateFormat
          .format(
            dateTime.toDateTimeLocal(),
          )
          .capitalizeFirst()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(formattedAmount),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      dense: true,
      onTap: onTap,
    );
  }

  Iterable<Widget> _buildBloodPressureChildren(BuildContext context) {
    return dailyHealthStatus.bloodPressures
        .sortedBy((e) => e.measuredAt.localDateTime, reverse: true)
        .map(
      (b) {
        return _buildValueTile(
          dateTime: b.measuredAt.localDateTime,
          formattedAmount: b.formattedAmount,
          onTap: () => Navigator.pushNamed(
            context,
            Routes.routeBloodPressureEdit,
            arguments: BloodPressureEditScreenArguments(b),
          ),
        );
      },
    );
  }

  Iterable<Widget> _buildPulseChildren(BuildContext context) {
    return dailyHealthStatus.pulses
        .sortedBy((e) => e.measuredAt.localDateTime, reverse: true)
        .map(
      (p) {
        return _buildValueTile(
          dateTime: p.measuredAt.localDateTime,
          formattedAmount: p.formattedAmount(context.appLocalizations),
          onTap: () => Navigator.pushNamed(
            context,
            Routes.routePulseEdit,
            arguments: PulseEditScreenArguments(p),
          ),
        );
      },
    );
  }

  Iterable<Widget> _buildChildren(BuildContext context) {
    if (indicator == HealthIndicator.bloodPressure) {
      return _buildBloodPressureChildren(context);
    }
    if (indicator == HealthIndicator.pulse) {
      return _buildPulseChildren(context);
    }

    throw ArgumentError.value(indicator);
  }
}

class DailyHealthStatusIndicatorTile extends StatelessWidget {
  static final _dateFormat = DateFormat('EEEE, MMMM d');

  final DailyHealthStatus dailyHealthStatus;
  final HealthIndicator indicator;

  const DailyHealthStatusIndicatorTile({
    Key key,
    @required this.dailyHealthStatus,
    @required this.indicator,
  }) : super(key: key);

  String getSubtitle(AppLocalizations appLocalizations) {
    if (indicator == HealthIndicator.swellings) {
      return dailyHealthStatus.swellings
          .map((s) => s.getLocalizedName(appLocalizations))
          .where((s) => s != null)
          .join(', ')
          .toLowerCase()
          .capitalizeFirst();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final date = dailyHealthStatus.date.calendarDate;
    final dateTitle =
        _dateFormat.format(date.toDateTimeUnspecified()).capitalizeFirst();
    final subtitle = getSubtitle(context.appLocalizations);

    final formattedAmount = dailyHealthStatus.getHealthIndicatorFormatted(
      indicator,
      context.appLocalizations,
    );

    return AppListTile(
      title: Text(dateTitle),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(formattedAmount),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(
        Routes.routeHealthStatusCreation,
        arguments: HealthStatusCreationScreenArguments(date: date),
      ),
    );
  }
}
