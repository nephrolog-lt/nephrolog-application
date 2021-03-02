import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/ui/forms/form_validators.dart';
import 'package:nephrogo/ui/forms/forms.dart';
import 'package:nephrogo/ui/general/app_future_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/utils/form_utils.dart';
import 'package:nephrogo_api_client/model/appetite_enum.dart';
import 'package:nephrogo_api_client/model/daily_health_status.dart';
import 'package:nephrogo_api_client/model/daily_health_status_request.dart';
import 'package:nephrogo_api_client/model/shortness_of_breath_enum.dart';
import 'package:nephrogo_api_client/model/swelling_difficulty_enum.dart';
import 'package:nephrogo_api_client/model/swelling_enum.dart';
import 'package:nephrogo_api_client/model/swelling_request.dart';
import 'package:nephrogo_api_client/model/well_feeling_enum.dart';
import 'package:time_machine/time_machine.dart';

class HealthStatusCreationScreenArguments {
  final LocalDate date;

  HealthStatusCreationScreenArguments({LocalDate date})
      : date = date ?? LocalDate.today();
}

class HealthStatusCreationScreen extends StatefulWidget {
  final LocalDate date;

  const HealthStatusCreationScreen({
    Key key,
    @required this.date,
  }) : super(key: key);

  @override
  _HealthStatusCreationScreenState createState() =>
      _HealthStatusCreationScreenState();
}

class _HealthStatusCreationScreenState
    extends State<HealthStatusCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat.MMMMd();

  final _apiService = ApiService();
  DailyHealthStatusRequestBuilder _requestBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dateFormat
            .format(widget.date.toDateTimeUnspecified())
            .capitalizeFirst()),
        actions: <Widget>[
          AppBarTextButton(
            onPressed: validateAndSave,
            child: Text(appLocalizations.save.toUpperCase()),
          ),
        ],
      ),
      body: AppFutureBuilder<DailyHealthStatus>(
        future: _apiService.getDailyHealthStatus(widget.date),
        builder: (context, healthStatus) {
          _requestBuilder = healthStatus?.toRequest()?.toBuilder() ??
              DailyHealthStatusRequestBuilder();

          _requestBuilder.date = widget.date.toOffsetDate();

          return _buildBody();
        },
      ),
    );
  }

  Widget _buildBody() {
    final formValidators = FormValidators(context);

    return Form(
      key: _formKey,
      child: Scrollbar(
        child: ListView(
          children: <Widget>[
            SmallSection(
              title: appLocalizations.healthStatusCreationSectionGeneralInfo,
              children: [
                AppDoubleInputField(
                  labelText: appLocalizations.weight,
                  fractionDigits: 1,
                  suffixText: 'kg',
                  textInputAction: TextInputAction.next,
                  helperText: appLocalizations.userProfileWeightHelper,
                  initialValue: _requestBuilder.weightKg,
                  validator: formValidators.numRangeValidator(30.0, 300.0),
                  onChanged: (value) => _requestBuilder.weightKg = value,
                ),
                AppIntegerFormField(
                  labelText: appLocalizations.healthStatusCreationUrine,
                  suffixText: 'ml',
                  textInputAction: TextInputAction.next,
                  initialValue: _requestBuilder.urineMl,
                  validator: formValidators.numRangeValidator(0, 10000),
                  onChanged: (value) => _requestBuilder.urineMl = value,
                ),
                AppDoubleInputField(
                  labelText: appLocalizations.healthStatusCreationGlucose,
                  textInputAction: TextInputAction.next,
                  suffixText: 'mmol/l',
                  fractionDigits: 2,
                  validator: formValidators.numRangeValidator(0.01, 100.0),
                  initialValue: _requestBuilder.glucose,
                  onChanged: (value) => _requestBuilder.glucose = value,
                ),
              ],
            ),
            SmallSection(
              title: appLocalizations.healthStatusCreationSwellings,
              children: [
                AppSelectFormField<SwellingDifficultyEnum>(
                  labelText:
                      appLocalizations.healthStatusCreationSwellingDifficulty,
                  dialogHelpText: appLocalizations
                      .healthStatusCreationSwellingDifficultyHelper,
                  initialValue: _requestBuilder.swellingDifficulty
                      ?.enumWithoutDefault(SwellingDifficultyEnum.unknown),
                  focusNextOnSelection: true,
                  onChanged: (v) =>
                      _requestBuilder.swellingDifficulty = v?.value,
                  items: [
                    AppSelectFormFieldItem(
                      text: '0+',
                      description: appLocalizations
                          .healthStatusCreationSwellingDifficulty0,
                      icon: const Icon(Icons.sentiment_very_satisfied),
                      value: SwellingDifficultyEnum.n0plus,
                    ),
                    AppSelectFormFieldItem(
                      text: '1+',
                      description: appLocalizations
                          .healthStatusCreationSwellingDifficulty1,
                      icon: const Icon(Icons.sentiment_satisfied),
                      value: SwellingDifficultyEnum.n1plus,
                    ),
                    AppSelectFormFieldItem(
                      text: '2+',
                      description: appLocalizations
                          .healthStatusCreationSwellingDifficulty2,
                      icon: const Icon(Icons.sentiment_dissatisfied),
                      value: SwellingDifficultyEnum.n2plus,
                    ),
                    AppSelectFormFieldItem(
                      text: '3+',
                      description: appLocalizations
                          .healthStatusCreationSwellingDifficulty3,
                      icon: const Icon(Icons.sentiment_very_dissatisfied),
                      value: SwellingDifficultyEnum.n3plus,
                    ),
                    AppSelectFormFieldItem(
                      text: '4+',
                      description: appLocalizations
                          .healthStatusCreationSwellingDifficulty4,
                      icon: const Icon(Icons.sick),
                      value: SwellingDifficultyEnum.n4plus,
                    ),
                  ],
                ),
                AppMultipleSelectFormField<SwellingEnum>(
                  initialValues: _requestBuilder.swellings
                      .build()
                      .map((e) => e.swelling)
                      .toList(),
                  labelText: appLocalizations.healthStatusCreationSwellings,
                  onChanged: (v) {
                    final swellings = v?.map<SwellingRequest>((e) {
                      final swellingBuilder = SwellingRequestBuilder();
                      swellingBuilder.swelling = e.value;

                      return swellingBuilder.build();
                    })?.toList();
                    _requestBuilder.swellings = ListBuilder(swellings ?? []);
                  },
                  focusNextOnSelection: true,
                  items: [
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationSwellingsLocalizationEyes,
                      value: SwellingEnum.eyes,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationSwellingsLocalizationWholeFace,
                      value: SwellingEnum.wholeFace,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationSwellingsLocalizationHandBreadth,
                      value: SwellingEnum.handBreadth,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationSwellingsLocalizationHands,
                      value: SwellingEnum.hands,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationSwellingsLocalizationBelly,
                      value: SwellingEnum.belly,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationSwellingsLocalizationKnees,
                      value: SwellingEnum.knees,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationSwellingsLocalizationFoot,
                      value: SwellingEnum.foot,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationSwellingsLocalizationWholeLegs,
                      value: SwellingEnum.wholeLegs,
                    ),
                  ],
                ),
              ],
            ),
            SmallSection(
              title: appLocalizations.healthStatusCreationWellFeeling,
              children: [
                AppSelectFormField<WellFeelingEnum>(
                  labelText: appLocalizations.healthStatusCreationWellFeeling,
                  initialValue: _requestBuilder.wellFeeling
                      ?.enumWithoutDefault(WellFeelingEnum.unknown),
                  onChanged: (v) => _requestBuilder.wellFeeling = v?.value,
                  focusNextOnSelection: true,
                  items: [
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationWellFeelingPerfect,
                      icon: const Icon(Icons.sentiment_very_satisfied),
                      value: WellFeelingEnum.perfect,
                    ),
                    AppSelectFormFieldItem(
                      text:
                          appLocalizations.healthStatusCreationWellFeelingGood,
                      icon: const Icon(Icons.sentiment_satisfied),
                      value: WellFeelingEnum.good,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationWellFeelingAverage,
                      icon: const Icon(Icons.sentiment_dissatisfied),
                      value: WellFeelingEnum.average,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations.healthStatusCreationWellFeelingBad,
                      icon: const Icon(Icons.sentiment_very_dissatisfied),
                      value: WellFeelingEnum.bad,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationWellFeelingVeryBad,
                      icon: const Icon(Icons.sick),
                      value: WellFeelingEnum.veryBad,
                    ),
                  ],
                ),
                AppSelectFormField<AppetiteEnum>(
                  labelText: appLocalizations.healthStatusCreationAppetite,
                  initialValue: _requestBuilder?.appetite
                      ?.enumWithoutDefault(AppetiteEnum.unknown),
                  onChanged: (v) => _requestBuilder.appetite = v?.value,
                  focusNextOnSelection: true,
                  items: [
                    AppSelectFormFieldItem(
                      text:
                          appLocalizations.healthStatusCreationAppetitePerfect,
                      icon: const Icon(Icons.sentiment_very_satisfied),
                      value: AppetiteEnum.perfect,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations.healthStatusCreationAppetiteGood,
                      icon: const Icon(Icons.sentiment_satisfied),
                      value: AppetiteEnum.good,
                    ),
                    AppSelectFormFieldItem(
                      text:
                          appLocalizations.healthStatusCreationAppetiteAverage,
                      icon: const Icon(Icons.sentiment_dissatisfied),
                      value: AppetiteEnum.average,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations.healthStatusCreationAppetiteBad,
                      icon: const Icon(Icons.sentiment_very_dissatisfied),
                      value: AppetiteEnum.bad,
                    ),
                    AppSelectFormFieldItem(
                      text:
                          appLocalizations.healthStatusCreationAppetiteVeryBad,
                      icon: const Icon(Icons.sick),
                      value: AppetiteEnum.veryBad,
                    ),
                  ],
                ),
                AppSelectFormField<ShortnessOfBreathEnum>(
                  labelText:
                      appLocalizations.healthStatusCreationShortnessOfBreath,
                  initialValue: _requestBuilder.shortnessOfBreath
                      ?.enumWithoutDefault(ShortnessOfBreathEnum.unknown),
                  onChanged: (v) =>
                      _requestBuilder.shortnessOfBreath = v?.value,
                  items: [
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationShortnessOfBreathNo,
                      icon: const Icon(Icons.sentiment_very_satisfied),
                      value: ShortnessOfBreathEnum.no,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationShortnessOfBreathLight,
                      description: appLocalizations
                          .healthStatusCreationShortnessOfBreathLightHelper,
                      icon: const Icon(Icons.sentiment_satisfied),
                      value: ShortnessOfBreathEnum.light,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationShortnessOfBreathAverage,
                      description: appLocalizations
                          .healthStatusCreationShortnessOfBreathAverageHelper,
                      icon: const Icon(Icons.sentiment_dissatisfied),
                      value: ShortnessOfBreathEnum.average,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationShortnessOfBreathSevere,
                      description: appLocalizations
                          .healthStatusCreationShortnessOfBreathSevereHelper,
                      icon: const Icon(Icons.sentiment_very_dissatisfied),
                      value: ShortnessOfBreathEnum.severe,
                    ),
                    AppSelectFormFieldItem(
                      text: appLocalizations
                          .healthStatusCreationShortnessOfBreathBackbreaking,
                      description: appLocalizations
                          .healthStatusCreationShortnessOfBreathBackbreakingHelper,
                      icon: const Icon(Icons.sick),
                      value: ShortnessOfBreathEnum.backbreaking,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> validateAndSave() async {
    return FormUtils.validateAndSave(
      context: context,
      formKey: _formKey,
      futureBuilder: () {
        final request = _requestBuilder.build();
        return _apiService.createOrUpdateDailyHealthStatus(request);
      },
    );
  }
}
