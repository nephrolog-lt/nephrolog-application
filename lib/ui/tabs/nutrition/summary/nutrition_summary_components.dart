import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/tabs/nutrition/product_search.dart';
import 'package:nephrogo_api_client/model/meal_type_enum.dart';
import 'package:time_machine/time_machine.dart';

class NutritionDailyListWithHeaderEmpty extends StatelessWidget {
  final Widget header;
  final LocalDate date;

  const NutritionDailyListWithHeaderEmpty({
    Key key,
    @required this.header,
    @required this.date,
  })  : assert(header != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final mealTypes =
        MealTypeEnum.values.where((v) => v != MealTypeEnum.unknown).toList();

    return ListView.builder(
      itemCount: mealTypes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return DateSwitcherHeaderSection(header: header);
        }

        final mealType = mealTypes[index - 1];

        return LargeSection(
          showDividers: true,
          title: Text(mealType.localizedName(context.appLocalizations)),
          trailing: OutlinedButton(
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
          ),
          children: const [],
        );
      },
    );
  }
}

class NutritionListWithHeaderEmpty extends StatelessWidget {
  final Widget header;

  const NutritionListWithHeaderEmpty({
    Key key,
    @required this.header,
  })  : assert(header != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DateSwitcherHeaderSection(header: header),
        Expanded(
          child: EmptyStateContainer(
            text: context.appLocalizations.weeklyNutrientsEmpty,
          ),
        ),
      ],
    );
  }
}

class DateSwitcherHeaderSection extends StatelessWidget {
  final Widget header;
  final List<Widget> children;

  const DateSwitcherHeaderSection({
    Key key,
    @required this.header,
    this.children,
  })  : assert(header != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasicSection(
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: header,
      ),
      showHeaderDivider: true,
      showDividers: true,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children ?? [],
    );
  }
}
