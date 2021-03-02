import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/constants.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/forms/form_validators.dart';
import 'package:nephrogo/ui/forms/forms.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/general/dialogs.dart';
import 'package:nephrogo/ui/tabs/nutrition/product_search.dart';
import 'package:nephrogo/utils/form_utils.dart';
import 'package:nephrogo_api_client/model/daily_nutrient_norms_with_totals.dart';
import 'package:nephrogo_api_client/model/intake.dart';
import 'package:nephrogo_api_client/model/intake_request.dart';
import 'package:nephrogo_api_client/model/meal_type_enum.dart';
import 'package:nephrogo_api_client/model/product.dart';
import 'package:time_machine/time_machine.dart';

import 'nutrition_components.dart';

class IntakeCreateScreenArguments extends Equatable {
  final DailyNutrientNormsWithTotals dailyNutrientNormsAndTotals;
  final Product product;
  final Intake intake;
  final LocalDate initialDate;
  final MealTypeEnum mealType;

  const IntakeCreateScreenArguments({
    @required this.dailyNutrientNormsAndTotals,
    @required this.mealType,
    this.product,
    this.intake,
    this.initialDate,
  })  : assert(dailyNutrientNormsAndTotals != null),
        assert(product != null || intake != null, 'Pass intake or product');

  @override
  List<Object> get props => [product, dailyNutrientNormsAndTotals];
}

class IntakeCreateScreen extends StatefulWidget {
  final DailyNutrientNormsWithTotals dailyNutrientNormsAndTotals;
  final Intake intake;
  final Product initialProduct;
  final LocalDate initialDate;
  final MealTypeEnum mealType;

  const IntakeCreateScreen({
    Key key,
    @required this.dailyNutrientNormsAndTotals,
    @required this.mealType,
    this.initialProduct,
    this.intake,
    this.initialDate,
  })  : assert(dailyNutrientNormsAndTotals != null),
        assert(
            initialProduct != null || intake != null, 'Pass intake or product'),
        super(key: key);

  @override
  _IntakeCreateScreenState createState() => _IntakeCreateScreenState();
}

class _IntakeSectionOption {
  Intake fakeIntake;
  FocusNode focusNode;

  _IntakeSectionOption(this.fakeIntake, this.focusNode);
}

class _IntakeCreateScreenState extends State<IntakeCreateScreen> {
  final _calendarDateFormat = DateFormat.yMEd();
  final _titleDateFormat = DateFormat.MMMMd();

  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  List<_IntakeSectionOption> _intakeSectionsOptions;

  LocalDateTime _consumedAt;

  MealTypeEnum _mealType;

  bool get _isAddNewProductButtonActive =>
      !_intakeSectionsOptions.any((e) => e.fakeIntake.amountG == 0);

  @override
  void initState() {
    super.initState();

    _consumedAt = LocalDateTime.now();
    _mealType = widget.mealType;

    if (widget.initialDate != null) {
      _consumedAt = _consumedAt.adjustDate((_) => widget.initialDate);
    }

    final fakedIntake =
        widget.initialProduct.fakeIntake(consumedAt: _consumedAt);

    _intakeSectionsOptions = [_IntakeSectionOption(fakedIntake, FocusNode())];
  }

  Future<Product> _showProductSearch() async {
    final excludeProductIds =
        _intakeSectionsOptions.map((e) => e.fakeIntake.product.id).toList();

    final product = await Navigator.pushNamed<Product>(
      context,
      Routes.routeProductSearch,
      arguments: ProductSearchScreenArguments(
        ProductSearchType.change,
        widget.mealType,
        excludeProductsIds: excludeProductIds,
      ),
    );

    if (product != null) {
      final fakedIntake = product.fakeIntake(
        consumedAt: _consumedAt,
        mealType: _mealType,
      );

      final intakeSectionOptions =
          _IntakeSectionOption(fakedIntake, FocusNode());

      setState(() => _intakeSectionsOptions.insert(0, intakeSectionOptions));

      intakeSectionOptions.focusNode.requestFocus();
    }

    return product;
  }

  @override
  Widget build(BuildContext context) {
    final formValidators = FormValidators(context);
    final title = _titleDateFormat
        .format(_consumedAt.toDateTimeLocal())
        .capitalizeFirst();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          AppBarTextButton(
            onPressed: _validateAndSaveIntake,
            child: Text(appLocalizations.save.toUpperCase()),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          child: ListView(
            children: <Widget>[
              BasicSection.single(
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton(
                      onPressed: _isAddNewProductButtonActive
                          ? _showProductSearch
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          appLocalizations.createAdditionalMeal.toUpperCase(),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < _intakeSectionsOptions.length; i++)
                _IntakeEditSection(
                  key: ObjectKey(_intakeSectionsOptions[i].fakeIntake.product),
                  focusNode: _intakeSectionsOptions[i].focusNode,
                  initialFakedIntake: _intakeSectionsOptions[i].fakeIntake,
                  dailyNutrientNormsAndTotals:
                      widget.dailyNutrientNormsAndTotals,
                  onChanged: _onIntakeChanged,
                  onDelete: _onIntakeDeleted,
                  initiallyExpanded: i + 1 == _intakeSectionsOptions.length,
                ),
              BasicSection(
                children: [
                  AppDatePickerFormField(
                    initialDate: _consumedAt.calendarDate,
                    selectedDate: _consumedAt.calendarDate,
                    firstDate: Constants.earliestDate,
                    lastDate: LocalDate.today(),
                    validator: formValidators.nonNull(),
                    dateFormat: _calendarDateFormat,
                    prefixIcon: const Icon(Icons.calendar_today),
                    onDateChanged: (date) {
                      setState(() {
                        _consumedAt = _consumedAt.adjustDate((_) => date);
                      });
                    },
                    labelText: appLocalizations.date,
                  ),
                  MealTypeSelectionFormField(
                    initialMealType: _mealType,
                    onChanged: (v) => _mealType = v,
                    onSaved: (v) => _mealType = v,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getIntakeIndex(Intake fakedIntake) {
    final index = _intakeSectionsOptions.indexWhere(
      (options) => options.fakeIntake.product.id == fakedIntake.product.id,
    );

    assert(index != -1, "Unable to find intake between intakes for creation");

    return index;
  }

  void _onIntakeChanged(Intake fakedIntake) {
    final index = _getIntakeIndex(fakedIntake);

    setState(() {
      _intakeSectionsOptions[index].fakeIntake = fakedIntake;
    });
  }

  void _onIntakeDeleted(Intake fakedIntake) {
    final index = _getIntakeIndex(fakedIntake);

    setState(() {
      _intakeSectionsOptions.removeAt(index);
    });
  }

  Iterable<IntakeRequest> _prepareIntakeRequests() sync* {
    for (final options in _intakeSectionsOptions) {
      final fakedIntake = options.fakeIntake;

      final builder = IntakeRequestBuilder();
      builder.productId = fakedIntake.product.id;
      builder.amountG = fakedIntake.amountG;
      builder.amountMl = fakedIntake.amountMl;
      builder.consumedAt = _consumedAt.withOffset(Offset.zero);
      builder.mealType = _mealType;

      yield builder.build();
    }
  }

  Future<List<Intake>> saveIntakes() async {
    final List<Intake> intakes = [];

    for (final request in _prepareIntakeRequests()) {
      final intake = await saveIntake(request);
      intakes.add(intake);
    }

    return intakes;
  }

  Future<Intake> saveIntake(IntakeRequest intakeRequest) {
    return _apiService.createIntake(intakeRequest);
  }

  Future<bool> _validateAndSaveIntake() async {
    FocusScope.of(context).unfocus();

    if (_intakeSectionsOptions.isEmpty) {
      await showAppDialog(
        context: context,
        title: appLocalizations.error,
        message: appLocalizations.formErrorNoMealsAdded,
      );

      return false;
    }

    return FormUtils.validateAndSave(
      context: context,
      formKey: _formKey,
      futureBuilder: saveIntakes,
    );
  }
}

class _IntakeEditSection extends StatefulWidget {
  final FocusNode focusNode;
  final Intake initialFakedIntake;
  final DailyNutrientNormsWithTotals dailyNutrientNormsAndTotals;
  final void Function(Intake fakedIntaked) onChanged;
  final void Function(Intake fakedIntaked) onDelete;
  final bool initiallyExpanded;

  const _IntakeEditSection({
    Key key,
    @required this.initialFakedIntake,
    @required this.dailyNutrientNormsAndTotals,
    @required this.onChanged,
    @required this.onDelete,
    @required this.focusNode,
    @required this.initiallyExpanded,
  })  : assert(initialFakedIntake != null),
        assert(dailyNutrientNormsAndTotals != null),
        assert(onChanged != null),
        assert(onDelete != null),
        super(key: key);

  @override
  _IntakeEditSectionState createState() => _IntakeEditSectionState();
}

class _IntakeEditSectionState extends State<_IntakeEditSection> {
  Intake intake;

  bool get isAmountInMilliliters => intake.product.densityGMl != null;

  LocalDateTime get _consumedAt => intake.consumedAt.localDateTime;

  Product get _product => intake.product;

  Intake get intakeOrIntakeWithDefaultAmount {
    if (intake.amountG != 0) {
      return intake;
    }

    return _createFakeIntake(100);
  }

  @override
  void initState() {
    super.initState();

    intake = widget.initialFakedIntake;
  }

  @override
  Widget build(BuildContext context) {
    final formValidators = FormValidators(context);

    final amount = isAmountInMilliliters ? intake.amountMl : intake.amountG;

    return SmallSection(
      title: _product.name,
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          semanticLabel: appLocalizations.delete,
        ),
        onPressed: () => widget.onDelete(intake),
      ),
      children: [
        AppIntegerFormField(
          focusNode: widget.focusNode,
          labelText: appLocalizations.mealCreationQuantity,
          initialValue: amount != 0 ? amount : null,
          suffixText: isAmountInMilliliters ? 'ml' : 'g',
          autoFocus: intake.amountG == 0,
          validator: formValidators.and(
            formValidators.nonNull(),
            formValidators.numRangeValidator(1, 10000),
          ),
          icon: CircleAvatar(
            backgroundColor: Theme.of(context).accentColor,
            child: const Icon(
              Icons.kitchen,
              color: Colors.white,
            ),
          ),
          onChanged: _onChanged,
        ),
        IntakeExpandableTile(
          intakeOrIntakeWithDefaultAmount,
          widget.dailyNutrientNormsAndTotals,
          initiallyExpanded: widget.initiallyExpanded,
          showDate: false,
        ),
      ],
    );
  }

  Intake _createFakeIntake(int amount) {
    int amountG;
    int amountMl;

    if (amount != null && isAmountInMilliliters) {
      amountMl = amount;
      amountG = (amount * _product.densityGMl).round();
    } else {
      amountG = amount ?? 0;
      amountMl = null;
    }

    return _product.fakeIntake(
      consumedAt: _consumedAt,
      amountG: amountG,
      amountMl: amountMl,
    );
  }

  void _onChanged(int amount) {
    setState(() {
      intake = _createFakeIntake(amount);
    });

    widget.onChanged(intake);
  }
}
