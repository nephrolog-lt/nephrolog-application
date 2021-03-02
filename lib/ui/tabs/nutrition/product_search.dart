import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/constants.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/general/app_steam_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/utils/utils.dart';
import 'package:nephrogo_api_client/model/daily_nutrient_norms_with_totals.dart';
import 'package:nephrogo_api_client/model/meal_type_enum.dart';
import 'package:nephrogo_api_client/model/product.dart';
import 'package:nephrogo_api_client/model/product_search_response.dart';
import 'package:time_machine/time_machine.dart';

import 'intake_create.dart';

enum ProductSearchType {
  choose,
  change,
}

class ProductSearchScreenArguments {
  final ProductSearchType searchType;
  final List<int> excludeProductsIds;
  final LocalDate date;
  final MealTypeEnum mealType;

  ProductSearchScreenArguments(
    this.searchType,
    this.mealType, {
    this.excludeProductsIds,
    this.date,
  });
}

class _Query {
  final String query;
  final bool submit;
  final bool wait;

  _Query(this.query, {@required this.wait, @required this.submit});
}

class ProductSearchScreen extends StatefulWidget {
  final ProductSearchType searchType;
  final List<int> excludeProductsIds;
  final LocalDate date;
  final MealTypeEnum mealType;

  const ProductSearchScreen({
    Key key,
    @required this.searchType,
    @required this.excludeProductsIds,
    @required this.mealType,
    this.date,
  })  : assert(searchType != null),
        assert(mealType != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState<T> extends State<ProductSearchScreen> {
  final _apiService = ApiService();

  final _searchDispatchDuration = const Duration(milliseconds: 200);

  String currentQuery = '';
  final focusNode = FocusNode();

  final _queryStreamController = StreamController<_Query>.broadcast();

  @override
  void dispose() {
    super.dispose();

    focusNode.dispose();
    _queryStreamController.close();
  }

  Stream<ProductSearchResponse> _buildStream() {
    return StreamGroup.merge([
      _queryStreamController.stream,
      Stream.value(_Query('', wait: false, submit: false))
    ])
        .asyncMap<_Query>((q) async {
          if (q.wait) {
            await Future.delayed(_searchDispatchDuration);
          }
          return q;
        })
        .where((q) => q.query == currentQuery)
        .asyncMap<ProductSearchResponse>(
          (q) => _apiService.getProducts(
            q.query,
            submit: q.submit,
            excludeProductIds: widget.excludeProductsIds,
            mealType: widget.mealType,
          ),
        )
        .where((p) => p.query == currentQuery);
  }

  void _changeQuery(String query, {@required bool submit}) {
    final trimmedQuery = query.trim();
    if (currentQuery == trimmedQuery) {
      return;
    }

    currentQuery = trimmedQuery;

    if (trimmedQuery.isEmpty || submit) {
      _queryStreamController.add(_Query(
        trimmedQuery,
        wait: false,
        submit: submit,
      ));
    } else if (trimmedQuery.length >= 2) {
      _queryStreamController.add(_Query(
        trimmedQuery,
        wait: true,
        submit: submit,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: TextField(
          onChanged: (q) => _changeQuery(q, submit: false),
          onSubmitted: (q) => _changeQuery(q, submit: true),
          focusNode: focusNode,
          style: theme.textTheme.headline6.copyWith(color: Colors.white),
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          autofocus: true,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: appLocalizations.productSearchTitle,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          cursorColor: Colors.white.withOpacity(0.9),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            Expanded(
              child: AppStreamBuilder<ProductSearchResponse>(
                stream: _buildStream(),
                builder: (context, productSearchResponse) {
                  final products = productSearchResponse.products.toList();

                  return Visibility(
                    visible: products.isNotEmpty,
                    replacement: SingleChildScrollView(
                      child: EmptyStateContainer(
                        text: appLocalizations.productSearchEmpty(currentQuery),
                      ),
                    ),
                    child: Scrollbar(
                      child: ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = products[index];

                          return ProductTile(
                            product: product,
                            onTap: () => close(
                              context,
                              product,
                              productSearchResponse.dailyNutrientNormsAndTotals,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            BasicSection(
              margin: EdgeInsets.zero,
              children: [
                AppListTile(
                  title: Text(appLocalizations.searchUnableToFindProduct),
                  trailing: OutlinedButton(
                    onPressed: _reportMissingProduct,
                    child: Text(appLocalizations.report.toUpperCase()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _reportMissingProduct() {
    return launchURL(Constants.reportMissingProductUrl);
  }

  Future close(
    BuildContext context,
    Product product,
    DailyNutrientNormsWithTotals dailyNutrientNormsAndTotals,
  ) async {
    if (widget.searchType == ProductSearchType.choose) {
      return Navigator.of(context).pushReplacementNamed(
        Routes.routeIntakeCreate,
        arguments: IntakeCreateScreenArguments(
          product: product,
          dailyNutrientNormsAndTotals: dailyNutrientNormsAndTotals,
          initialDate: widget.date,
          mealType: widget.mealType,
        ),
      );
    }

    Navigator.pop(context, product);
  }
}

class ProductTile extends StatelessWidget {
  final Product product;
  final GestureTapCallback onTap;

  ProductTile({
    @required this.product,
    @required this.onTap,
  }) : super(key: ObjectKey(product));

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: Text(product.name),
      leading: ProductKindIcon(productKind: product.productKind),
      onTap: onTap,
    );
  }
}
