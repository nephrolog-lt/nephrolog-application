import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/constants.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/ui/forms/form_validators.dart';
import 'package:nephrogo/ui/forms/forms.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/general/progress_dialog.dart';
import 'package:nephrogo/utils/form_utils.dart';
import 'package:nephrogo_api_client/model/daily_nutrient_norms_with_totals.dart';
import 'package:nephrogo_api_client/model/intake.dart';
import 'package:nephrogo_api_client/model/intake_request.dart';
import 'package:nephrogo_api_client/model/meal_type_enum.dart';
import 'package:nephrogo_api_client/model/product.dart';

import 'nutrition_components.dart';

class IntakeEditScreenArguments extends Equatable {
  final DailyNutrientNormsWithTotals dailyNutrientNormsAndTotals;
  final Intake intake;

  const IntakeEditScreenArguments(
    this.intake,
    this.dailyNutrientNormsAndTotals,
  )   : assert(dailyNutrientNormsAndTotals != null),
        assert(intake != null);

  @override
  List<Object> get props => [intake, dailyNutrientNormsAndTotals];
}

class IntakeEditScreen extends StatefulWidget {
  final DailyNutrientNormsWithTotals dailyNutrientNormsAndTotals;
  final Intake intake;

  const IntakeEditScreen({
    Key key,
    @required this.dailyNutrientNormsAndTotals,
    @required this.intake,
  })  : assert(dailyNutrientNormsAndTotals != null),
        assert(intake != null),
        super(key: key);

  @override
  _IntakeEditScreenState createState() => _IntakeEditScreenState();
}

class _IntakeEditScreenState extends State<IntakeEditScreen> {
  static final _dateFormat = DateFormat.yMEd();

  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _intakeBuilder = IntakeRequestBuilder();

  int amountG;
  int amountMl;

  MealTypeEnum mealType;

  Product get product => widget.intake.product;

  DateTime _consumedAt;

  bool get isAmountInMilliliters => product.densityGMl != null;

  @override
  void initState() {
    super.initState();

    mealType = widget.intake.mealType;
    amountG = widget.intake.amountG;
    amountMl = widget.intake.amountMl;

    _intakeBuilder.productId = product.id;

    _consumedAt = widget.intake.consumedAt.toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final formValidators = FormValidators(context);
    final title = product.name;

    final fakedIntake = product.fakeIntake(
      consumedAt: _consumedAt,
      amountG: amountG,
      amountMl: amountMl,
      mealType: mealType,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(primary: Colors.white),
            onPressed: () => validateAndSaveIntake(context),
            child: Text(appLocalizations.update.toUpperCase()),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SmallSection(
                  title: product.name,
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      semanticLabel: appLocalizations.delete,
                    ),
                    onPressed: () => deleteIntake(widget.intake.id),
                  ),
                  children: [
                    AppIntegerFormField(
                      labelText: appLocalizations.mealCreationQuantity,
                      initialValue: isAmountInMilliliters
                          ? widget.intake.amountMl
                          : widget.intake.amountG,
                      suffixText: isAmountInMilliliters ? 'ml' : 'g',
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
                      onChanged: (v) {
                        final amount = v ?? 0;
                        setState(() {
                          if (v != null && isAmountInMilliliters) {
                            amountMl = amount;
                            amountG = (amount * product.densityGMl).round();
                          } else {
                            amountG = amount;
                            amountMl = null;
                          }
                        });
                      },
                      onSaved: (_) {
                        _intakeBuilder.amountG = amountG;
                        _intakeBuilder.amountMl = amountMl;
                      },
                    ),
                    IntakeExpandableTile(
                      fakedIntake,
                      widget.dailyNutrientNormsAndTotals,
                      initiallyExpanded: true,
                    )
                  ],
                ),
                BasicSection(
                  children: [
                    AppDatePickerFormField(
                      initialDate: _consumedAt,
                      selectedDate: _consumedAt,
                      firstDate: Constants.earliestDate,
                      lastDate: DateTime.now(),
                      validator: formValidators.nonNull(),
                      dateFormat: _dateFormat,
                      prefixIcon: const Icon(Icons.calendar_today),
                      onDateChanged: (dt) {
                        final ldt = dt.toLocal();
                        _consumedAt = DateTime(
                          ldt.year,
                          ldt.month,
                          ldt.day,
                          _consumedAt.hour,
                          _consumedAt.minute,
                        );
                      },
                      onDateSaved: (dt) =>
                          _intakeBuilder.consumedAt = _consumedAt.toUtc(),
                      labelText: appLocalizations.mealCreationDate,
                    ),
                    MealTypeSelectionFormField(
                      initialMealType: mealType,
                      onChanged: (v) => mealType = v,
                      onSaved: (v) => _intakeBuilder.mealType = mealType = v,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future deleteIntake(int id) async {
    final appLocalizations = AppLocalizations.of(context);

    final delete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.delete),
          content: Text(appLocalizations.deleteConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(appLocalizations.dialogCancel.toUpperCase()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(appLocalizations.delete.toUpperCase()),
            ),
          ],
        );
      },
    );

    if (delete) {
      final deletingFuture = _apiService.deleteIntake(id);
      await ProgressDialog(context).showForFuture(deletingFuture);
      Navigator.pop(context);
    }
  }

  Future<Intake> _updateIntake() {
    return _apiService.updateIntake(widget.intake.id, _intakeBuilder.build());
  }

  Future validateAndSaveIntake(BuildContext context) {
    return FormUtils.validateAndSave(
      context: context,
      formKey: _formKey,
      futureBuilder: _updateIntake,
    );
  }
}
