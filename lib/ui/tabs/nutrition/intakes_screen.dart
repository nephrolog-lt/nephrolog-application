import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrolog/models/contract.dart';
import 'package:nephrolog/extensions/string_extensions.dart';
import 'package:nephrolog/extensions/date_extensions.dart';
import 'package:nephrolog/extensions/contract_extensions.dart';
import 'package:nephrolog/services/api_service.dart';
import 'package:nephrolog/ui/charts/indicator_bar_chart.dart';
import 'package:nephrolog/ui/general/components.dart';
import 'package:nephrolog/ui/general/progress_indicator.dart';

class IntakesScreenArguments {
  final IndicatorType intakesScreenType;

  IntakesScreenArguments(this.intakesScreenType);
}

class IntakesScreen extends StatefulWidget {
  final IndicatorType type;

  const IntakesScreen({Key key, @required this.type}) : super(key: key);

  @override
  _IntakesScreenState createState() => _IntakesScreenState();
}

class _IntakesScreenState extends State<IntakesScreen> {
  static final dateFormatter = DateFormat.MMMMd();

  // It's hacky, but let's load pages nearby
  final pageController = PageController(viewportFraction: 0.9999999);

  ValueNotifier<IndicatorType> indicatorChangeNotifier;

  final DateTime now = DateTime.now();

  DateTime initialWeekStart;
  DateTime initialWeekEnd;

  DateTime weekStart;
  DateTime weekEnd;
  IndicatorType type;

  @override
  void initState() {
    super.initState();

    type = widget.type;

    final weekStartEnd = now.startAndEndOfWeek();

    weekStart = initialWeekStart = weekStartEnd.item1;
    weekEnd = initialWeekEnd = weekStartEnd.item2;

    indicatorChangeNotifier = ValueNotifier<IndicatorType>(type);
    pageController.addListener(onPageChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIndicatorSelectionPopupMenu,
        label: Text("MEDŽIAGA"),
        icon: Icon(Icons.swap_horizontal_circle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              elevation: 1,
              child: BasicSection(
                padding: EdgeInsets.zero,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: advanceToPreviousDateRange,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _getDateRangeFormatted(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed:
                            hasNextDateRange() ? advanceToNextDateRange : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _WeeklyIntakesPager(
              pageController: pageController,
              indicatorChangeNotifier: indicatorChangeNotifier,
              initialWeekStart: initialWeekStart,
              initialWeekEnd: initialWeekEnd,
            ),
          ),
        ],
      ),
    );
  }

  void onPageChanged() {
    if (pageController.page == pageController.page.roundToDouble()) {
      changeWeek(pageController.page.toInt());
    }
  }

  DateTime calculateWeekStart(int n) {
    final changeDuration = Duration(days: 7 * n);

    return initialWeekStart.subtract(changeDuration);
  }

  DateTime calculateWeekEnd(int n) {
    final changeDuration = Duration(days: 7 * n);

    return initialWeekEnd.subtract(changeDuration);
  }

  changeWeek(int index) {
    setState(() {
      weekStart = calculateWeekStart(index);
      weekEnd = calculateWeekEnd(index);
    });
  }

  String _getTitle() {
    switch (type) {
      case IndicatorType.energy:
        return "Energijos suvartojimas";
      case IndicatorType.liquids:
        return "Skysčių suvartojimas";
      case IndicatorType.proteins:
        return "Baltymų suvartojimas";
      case IndicatorType.sodium:
        return "Natrio suvartojimas";
      case IndicatorType.potassium:
        return "Kalio suvartojimas";
      case IndicatorType.phosphorus:
        return "Fosforo suvartojimas";
      default:
        throw ArgumentError.value(
            this, "type", "Unable to map indicator to name");
    }
  }

  _changeIndicator(IndicatorType selectedType) {
    setState(() {
      type = selectedType;
      indicatorChangeNotifier.value = selectedType;
    });
  }

  Future _showIndicatorSelectionPopupMenu() async {
    final options = IndicatorType.values.map((t) {
      return SimpleDialogOption(
        child: Text(t.name),
        onPressed: () => Navigator.pop(context, t),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      );
    }).toList();

    // show the dialog
    final selectedType = await showDialog<IndicatorType>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Pasirinkite maisto medžiagą'),
          children: options,
        );
      },
    );

    if (selectedType != null) {
      _changeIndicator(selectedType);
    }
  }

  bool hasNextDateRange() => weekEnd.isBefore(DateTime.now());

  advanceToNextDateRange() {
    pageController.previousPage(
        duration: const Duration(milliseconds: 700), curve: Curves.ease);
  }

  advanceToPreviousDateRange() {
    pageController.nextPage(
        duration: const Duration(milliseconds: 700), curve: Curves.ease);
  }

  String _getDateRangeFormatted() {
    return "${dateFormatter.format(weekStart).capitalizeFirst()} – "
        "${dateFormatter.format(weekEnd).capitalizeFirst()}";
  }

  @override
  void dispose() {
    pageController.removeListener(onPageChanged);

    super.dispose();
  }
}

class _WeeklyIntakesPager extends StatefulWidget {
  final PageController pageController;
  final ValueNotifier<IndicatorType> indicatorChangeNotifier;
  final DateTime initialWeekStart;
  final DateTime initialWeekEnd;

  const _WeeklyIntakesPager({
    Key key,
    @required this.pageController,
    @required this.indicatorChangeNotifier,
    @required this.initialWeekStart,
    @required this.initialWeekEnd,
  }) : super(key: key);

  @override
  _WeeklyIntakesPagerState createState() => _WeeklyIntakesPagerState();
}

class _WeeklyIntakesPagerState extends State<_WeeklyIntakesPager> {
  IndicatorType type;

  DateTime weekStart;
  DateTime weekEnd;

  @override
  void initState() {
    super.initState();

    type = widget.indicatorChangeNotifier.value;
    weekStart = widget.initialWeekStart;
    weekEnd = widget.initialWeekEnd;

    widget.indicatorChangeNotifier.addListener(onIndicatorChanged);
  }

  onIndicatorChanged() {
    setState(() {
      type = widget.indicatorChangeNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.pageController,
      onPageChanged: changeWeek,
      reverse: true,
      itemBuilder: (context, index) {
        return _WeeklyIntakesComponent(
          type: type,
          weekStart: weekStart,
          weekEnd: weekEnd,
        );
      },
    );
  }

  DateTime calculateWeekStart(int n) {
    final changeDuration = Duration(days: 7 * n);

    return widget.initialWeekStart.subtract(changeDuration);
  }

  DateTime calculateWeekEnd(int n) {
    final changeDuration = Duration(days: 7 * n);

    return widget.initialWeekEnd.subtract(changeDuration);
  }

  changeWeek(int index) {
    setState(() {
      weekStart = calculateWeekStart(index);
      weekEnd = calculateWeekEnd(index);
    });
  }

  @override
  void dispose() {
    widget.indicatorChangeNotifier.removeListener(onIndicatorChanged);

    super.dispose();
  }
}

class _WeeklyIntakesComponent extends StatelessWidget {
  final apiService = const ApiService();

  final IndicatorType type;

  final DateTime weekStart;
  final DateTime weekEnd;

  const _WeeklyIntakesComponent({
    Key key,
    @required this.type,
    @required this.weekStart,
    @required this.weekEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DailyIntakesResponse>(
      future: apiService.getUserIntakesResponse(weekStart, weekEnd),
      builder:
          (BuildContext context, AsyncSnapshot<DailyIntakesResponse> snapshot) {
        if (snapshot.hasData) {
          final dailyIntakes = snapshot.data.dailyIntakes;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: BasicSection(
                  children: [
                    IndicatorBarChart(
                      dailyIntakes: dailyIntakes,
                      type: type,
                    ),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return DailyIntakeSection(
                      type: type,
                      dailyIntake: dailyIntakes[index],
                    );
                  },
                  childCount: dailyIntakes.length,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: 64),
              )
            ],
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error));
        }

        return Center(child: AppProgressIndicator());
      },
    );
  }
}

class DailyIntakeSection extends StatelessWidget {
  static final _dateFormat = DateFormat("EEEE, d");

  final IndicatorType type;
  final DailyIntake dailyIntake;

  DailyIntakeSection({
    Key key,
    @required this.type,
    @required this.dailyIntake,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ratio = dailyIntake.getIndicatorConsumptionRatio(type);
    final dailyNormFormatted =
        dailyIntake.userIntakeNorms.getFormattedIndicator(type);
    final consumptionFormatted = dailyIntake.getFormattedDailyTotal(type);

    return LargeSection(
      title: _dateFormat.format(dailyIntake.date).capitalizeFirst() + " d.",
      leading: _getVisualIndicator(ratio),
      subTitle: "$consumptionFormatted iš $dailyNormFormatted",
      children: dailyIntake.intakes
          .map(
            (intake) => IndicatorIntakeTile(
              intake: intake,
              type: type,
            ),
          )
          .toList(),
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
          "${(percent * 100).toInt()}%",
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
  static final dateFormat = DateFormat(
    "MMMM d HH:mm",
  );

  final Intake intake;
  final IndicatorType type;

  const IndicatorIntakeTile({
    Key key,
    this.intake,
    this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = intake.product;

    final dateFormatted = dateFormat.format(intake.dateTime).capitalizeFirst();

    return ListTile(
      title: Text(product.name),
      contentPadding: EdgeInsets.zero,
      subtitle: Text(
        "${intake.getAmountFormatted()} | $dateFormatted",
      ),
      leading: ProductKindIcon(productKind: product.kind),
      trailing: Text(intake.getFormattedIndicatorConsumption(type)),
    );
  }
}
