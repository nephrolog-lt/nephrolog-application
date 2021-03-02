import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:collection_ext/iterables.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/extensions/collection_extensions.dart';
import 'package:nephrogo/extensions/date_extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo_api_client/model/appetite_enum.dart';
import 'package:nephrogo_api_client/model/automatic_peritoneal_dialysis.dart';
import 'package:nephrogo_api_client/model/automatic_peritoneal_dialysis_request.dart';
import 'package:nephrogo_api_client/model/blood_pressure.dart';
import 'package:nephrogo_api_client/model/blood_pressure_request.dart';
import 'package:nephrogo_api_client/model/daily_health_status.dart';
import 'package:nephrogo_api_client/model/daily_health_status_request.dart';
import 'package:nephrogo_api_client/model/daily_intakes_light_report.dart';
import 'package:nephrogo_api_client/model/daily_intakes_report.dart';
import 'package:nephrogo_api_client/model/daily_nutrient_consumption.dart';
import 'package:nephrogo_api_client/model/daily_nutrient_norms_with_totals.dart';
import 'package:nephrogo_api_client/model/dialysate_color_enum.dart';
import 'package:nephrogo_api_client/model/dialysis_solution_enum.dart';
import 'package:nephrogo_api_client/model/intake.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis_request.dart';
import 'package:nephrogo_api_client/model/meal_type_enum.dart';
import 'package:nephrogo_api_client/model/product.dart';
import 'package:nephrogo_api_client/model/product_kind_enum.dart';
import 'package:nephrogo_api_client/model/pulse.dart';
import 'package:nephrogo_api_client/model/pulse_request.dart';
import 'package:nephrogo_api_client/model/shortness_of_breath_enum.dart';
import 'package:nephrogo_api_client/model/swelling.dart';
import 'package:nephrogo_api_client/model/swelling_difficulty_enum.dart';
import 'package:nephrogo_api_client/model/swelling_enum.dart';
import 'package:nephrogo_api_client/model/swelling_request.dart';
import 'package:nephrogo_api_client/model/well_feeling_enum.dart';
import 'package:time_machine/time_machine.dart';
import 'package:tuple/tuple.dart';

final _numberFormatter = NumberFormat.decimalPattern();

String _formatAmount<T extends num>(T amount, String dim) {
  if (amount is double && amount < 1000) {
    final roundedDouble = (amount * 100).round() / 100;

    return '${_numberFormatter.format(roundedDouble)} $dim';
  }

  return '${_numberFormatter.format(amount)} $dim';
}

extension ProductExtensions on Product {
  num _getNutrientAmount(Nutrient nutrient) {
    switch (nutrient) {
      case Nutrient.potassium:
        return potassiumMg;
      case Nutrient.proteins:
        return proteinsMg;
      case Nutrient.sodium:
        return sodiumMg;
      case Nutrient.phosphorus:
        return phosphorusMg;
      case Nutrient.liquids:
        return liquidsMl;
      case Nutrient.energy:
        return energyKcal;
      case Nutrient.fat:
        return fatMg;
      case Nutrient.carbohydrate:
        return carbohydratesMg;
    }
    throw ArgumentError.value(
        nutrient, 'nutrient', 'Unable to map indicator to amount');
  }

  int _calculateTotalNutrientAmount(Nutrient nutrient, int amountG) {
    final nutrientAmount = _getNutrientAmount(nutrient);
    final nutrientAmountRatio = amountG / 100;

    return (nutrientAmount * nutrientAmountRatio).round();
  }

  String getFormattedTotalAmount(Nutrient nutrient, int amountG) {
    final nutrientAmount = _calculateTotalNutrientAmount(nutrient, amountG);

    return nutrient.formatAmount(nutrientAmount);
  }

  int getNutrientNormPercentage(Nutrient nutrient, int amountG, int norm) {
    return ((_calculateTotalNutrientAmount(nutrient, amountG) / norm) * 100)
        .round();
  }

  bool get isDrink => productKind == ProductKindEnum.drink;

  // This is used for generating intakes required to show nutrient amounts
  // after searching for a product
  Intake fakeIntake({
    @required LocalDateTime consumedAt,
    @required MealTypeEnum mealType,
    int amountG = 0,
    int amountMl,
  }) {
    assert(amountG != null);

    final builder = IntakeBuilder();

    builder.id = 0;
    builder.consumedAt = consumedAt.withOffset(Offset.zero);

    builder.amountG = amountG;

    builder.mealType = mealType;

    if (densityGMl != null) {
      if (amountMl != null) {
        builder.amountMl = amountMl;
      } else {
        builder.amountMl = (amountG / densityGMl).round();
      }
    }

    builder.potassiumMg =
        _calculateTotalNutrientAmount(Nutrient.potassium, amountG);
    builder.proteinsMg =
        _calculateTotalNutrientAmount(Nutrient.proteins, amountG);
    builder.sodiumMg = _calculateTotalNutrientAmount(Nutrient.sodium, amountG);
    builder.phosphorusMg =
        _calculateTotalNutrientAmount(Nutrient.phosphorus, amountG);
    builder.energyKcal =
        _calculateTotalNutrientAmount(Nutrient.energy, amountG);
    builder.liquidsMl =
        _calculateTotalNutrientAmount(Nutrient.liquids, amountG);
    builder.carbohydratesMg =
        _calculateTotalNutrientAmount(Nutrient.carbohydrate, amountG);
    builder.fatMg = _calculateTotalNutrientAmount(Nutrient.fat, amountG);

    builder.product = toBuilder();

    return builder.build();
  }
}

extension DailyNutrientConsumptionExtensions on DailyNutrientConsumption {
  int totalConsumptionRoundedPercentage() {
    if (norm == null) {
      return null;
    }

    return ((total / norm) * 100).round();
  }

  double get normPercentage {
    if (norm == null) {
      return null;
    }

    return total / norm;
  }

  int normPercentageRounded(int nutrientAmount) {
    if (norm == null) {
      return null;
    }

    return ((nutrientAmount / norm) * 100).round();
  }

  bool get isNormExists => norm != null;

  bool get normExceeded {
    if (norm == null) {
      return null;
    }

    return total > norm;
  }
}

extension DailyIntakesReportExtensions on DailyIntakesReport {
  DailyIntakesLightReport toLightReport() {
    final builder = DailyIntakesLightReportBuilder();

    builder.nutrientNormsAndTotals = dailyNutrientNormsAndTotals.toBuilder();
    builder.date = date;

    return builder.build();
  }

  Iterable<Tuple2<MealTypeEnum, List<Intake>>>
      getIntakesGroupedByMealType() sync* {
    final sortedIntakes =
        intakes.sortedBy((i) => i.consumedAt.localDateTime, reverse: true);
    final groups = sortedIntakes.groupBy((intake) => intake.mealType);

    final mealTypes = [
      MealTypeEnum.dinner,
      MealTypeEnum.lunch,
      MealTypeEnum.breakfast,
      MealTypeEnum.snack,
      MealTypeEnum.unknown,
    ];

    for (final mealType in mealTypes) {
      if (groups.containsKey(mealType)) {
        yield Tuple2(mealType, groups[mealType]);
      } else if (mealType != MealTypeEnum.unknown) {
        yield Tuple2(mealType, []);
      }
    }
  }

  Iterable<DailyMealTypeNutrientConsumption> dailyMealTypeNutrientConsumptions({
    @required Nutrient nutrient,
    bool includeEmpty = false,
  }) sync* {
    final dailyTotal = intakes.sumBy((_, e) => e.getNutrientAmount(nutrient));
    final groups = intakes.groupBy((intake) => intake.mealType);

    final mealTypes = [
      ...MealTypeEnum.values.where((e) => e != MealTypeEnum.unknown).toList(),
      MealTypeEnum.unknown
    ];

    for (final mealType in mealTypes) {
      if (groups.containsKey(mealType)) {
        final drinksTotal = groups[mealType]
            .where((i) => i.product.isDrink)
            .sumBy((_, e) => e.getNutrientAmount(nutrient));

        final foodTotal = groups[mealType]
            .where((i) => !i.product.isDrink)
            .sumBy((_, e) => e.getNutrientAmount(nutrient));

        yield DailyMealTypeNutrientConsumption(
          date: date.calendarDate,
          nutrient: nutrient,
          mealType: mealType,
          drinksTotal: drinksTotal,
          foodTotal: foodTotal,
          dailyTotal: dailyTotal,
        );
      } else if (includeEmpty && mealType != MealTypeEnum.unknown) {
        yield DailyMealTypeNutrientConsumption(
          date: date.calendarDate,
          nutrient: nutrient,
          mealType: mealType,
          drinksTotal: 0,
          foodTotal: 0,
          dailyTotal: dailyTotal,
        );
      }
    }
  }
}

extension MealTypeExtensions on MealTypeEnum {
  String localizedName(AppLocalizations appLocalizations) {
    switch (this) {
      case MealTypeEnum.breakfast:
        return appLocalizations.breakfast;
      case MealTypeEnum.lunch:
        return appLocalizations.lunch;
      case MealTypeEnum.dinner:
        return appLocalizations.dinner;
      case MealTypeEnum.snack:
        return appLocalizations.snacks;
      case MealTypeEnum.unknown:
        return appLocalizations.otherMeals;
    }
    throw ArgumentError.value(this, 'mealType', 'Unable to map mealType');
  }

  IconData get icon {
    switch (this) {
      case MealTypeEnum.breakfast:
        return Icons.breakfast_dining;
      case MealTypeEnum.lunch:
        return Icons.dinner_dining;
      case MealTypeEnum.dinner:
        return Icons.nights_stay;
      case MealTypeEnum.snack:
        return Icons.bakery_dining;
      case MealTypeEnum.unknown:
        return Icons.local_dining;
    }
    throw ArgumentError.value(this, 'mealType', 'Unable to map mealType');
  }
}

extension DailyNutrientNormsWithTotalsExtensions
    on DailyNutrientNormsWithTotals {
  DailyNutrientConsumption getDailyNutrientConsumption(Nutrient nutrient) {
    switch (nutrient) {
      case Nutrient.potassium:
        return potassiumMg;
      case Nutrient.proteins:
        return proteinsMg;
      case Nutrient.sodium:
        return sodiumMg;
      case Nutrient.phosphorus:
        return phosphorusMg;
      case Nutrient.liquids:
        return liquidsMl;
      case Nutrient.energy:
        return energyKcal;
      case Nutrient.fat:
        return fatMg;
      case Nutrient.carbohydrate:
        return carbohydratesMg;
    }
    throw ArgumentError.value(
        nutrient, 'nutrient', 'Unable to map indicator to amount');
  }

  String getNutrientTotalAmountFormatted(Nutrient nutrient) {
    final amount = getDailyNutrientConsumption(nutrient).total;
    assert(amount != null);

    return nutrient.formatAmount(amount);
  }

  String getNutrientNormFormatted(Nutrient nutrient) {
    final norm = getDailyNutrientConsumption(nutrient).norm;
    if (norm == null) {
      return null;
    }

    return nutrient.formatAmount(norm);
  }

  int getRoundedNormPercentage(Nutrient nutrient) {
    final consumption = getDailyNutrientConsumption(nutrient);

    if (consumption.norm == null) {
      return null;
    }

    return ((consumption.total / consumption.norm) * 100).round();
  }

  int normsExceededCount() {
    return Nutrient.values
        .map(getDailyNutrientConsumption)
        .where((c) => c.normExceeded == true)
        .length;
  }

  bool isAtLeastOneNormExceeded() {
    return Nutrient.values
        .map(getDailyNutrientConsumption)
        .any((c) => c.normExceeded == true);
  }

  bool isAtLeastOneTotalNonZeo() {
    return Nutrient.values
        .map(getDailyNutrientConsumption)
        .any((c) => c.total != 0);
  }

  List<Nutrient> getSortedNutrientsByExistence() {
    return Nutrient.values
        .sortedBy((n) => getDailyNutrientConsumption(n).isNormExists ? 0 : 1)
        .toList();
  }
}

extension IntakeExtension on Intake {
  int getNutrientAmount(Nutrient nutrient) {
    switch (nutrient) {
      case Nutrient.energy:
        return energyKcal;
      case Nutrient.liquids:
        return liquidsMl;
      case Nutrient.proteins:
        return proteinsMg;
      case Nutrient.sodium:
        return sodiumMg;
      case Nutrient.potassium:
        return potassiumMg;
      case Nutrient.phosphorus:
        return phosphorusMg;
      case Nutrient.fat:
        return fatMg;
      case Nutrient.carbohydrate:
        return carbohydratesMg;
    }
    throw ArgumentError.value(
        nutrient, 'nutrient', 'Unable to map indicator to amount');
  }

  String getNutrientAmountFormatted(Nutrient nutrient) {
    final amount = getNutrientAmount(nutrient);

    return nutrient.formatAmount(amount);
  }

  String getAmountFormatted() {
    if (amountMl != null) {
      return _formatAmount(amountMl, 'ml');
    }

    return _formatAmount(amountG, 'g');
  }
}

extension NutrientExtensions on Nutrient {
  String name(AppLocalizations appLocalizations) {
    switch (this) {
      case Nutrient.energy:
        return appLocalizations.energy;
      case Nutrient.liquids:
        return appLocalizations.liquids;
      case Nutrient.proteins:
        return appLocalizations.proteins;
      case Nutrient.sodium:
        return appLocalizations.sodium;
      case Nutrient.potassium:
        return appLocalizations.potassium;
      case Nutrient.phosphorus:
        return appLocalizations.phosphorus;
      case Nutrient.fat:
        return appLocalizations.fat;
      case Nutrient.carbohydrate:
        return appLocalizations.carbohydrate;
    }
    throw ArgumentError.value(
        this, 'nutrient', 'Unable to map nutrient to name');
  }

  String consumptionName(AppLocalizations appLocalizations) {
    switch (this) {
      case Nutrient.energy:
        return appLocalizations.consumptionEnergy;
      case Nutrient.liquids:
        return appLocalizations.consumptionLiquids;
      case Nutrient.proteins:
        return appLocalizations.consumptionProteins;
      case Nutrient.sodium:
        return appLocalizations.consumptionSodium;
      case Nutrient.potassium:
        return appLocalizations.consumptionPotassium;
      case Nutrient.phosphorus:
        return appLocalizations.consumptionPhosphorus;
      case Nutrient.fat:
        return appLocalizations.consumptionFat;
      case Nutrient.carbohydrate:
        return appLocalizations.consumptionCarbohydrate;
    }

    throw ArgumentError.value(
      this,
      'nutrient',
      'Unable to map nutrient to name',
    );
  }

  String formatAmount(int amount) {
    return _formatAmount(amount * scale, scaledDimension);
  }

  num get scale {
    switch (this) {
      case Nutrient.energy:
      case Nutrient.liquids:
        return 1;
      default:
        return 1e-3;
    }
  }

  int get decimalPlaces {
    switch (this) {
      case Nutrient.energy:
      case Nutrient.liquids:
        return 0;
      default:
        return 2;
    }
  }

  String get scaledDimension {
    switch (this) {
      case Nutrient.energy:
        return 'kcal';
      case Nutrient.proteins:
      case Nutrient.sodium:
      case Nutrient.potassium:
      case Nutrient.phosphorus:
      case Nutrient.fat:
      case Nutrient.carbohydrate:
        return 'g';
      case Nutrient.liquids:
        return 'ml';
    }
    throw ArgumentError.value(
        this, 'nutrient', 'Unable to map nutrient to dimension');
  }
}

extension SwellingExtension on Swelling {
  String getLocalizedName(AppLocalizations appLocalizations) {
    switch (swelling) {
      case SwellingEnum.eyes:
        return appLocalizations.healthStatusCreationSwellingsLocalizationEyes;
      case SwellingEnum.wholeFace:
        return appLocalizations
            .healthStatusCreationSwellingsLocalizationWholeFace;
      case SwellingEnum.handBreadth:
        return appLocalizations
            .healthStatusCreationSwellingsLocalizationHandBreadth;
      case SwellingEnum.hands:
        return appLocalizations.healthStatusCreationSwellingsLocalizationHands;
      case SwellingEnum.belly:
        return appLocalizations.healthStatusCreationSwellingsLocalizationBelly;
      case SwellingEnum.knees:
        return appLocalizations.healthStatusCreationSwellingsLocalizationKnees;
      case SwellingEnum.foot:
        return appLocalizations.healthStatusCreationSwellingsLocalizationFoot;
      case SwellingEnum.wholeLegs:
        return appLocalizations
            .healthStatusCreationSwellingsLocalizationWholeLegs;
      case SwellingEnum.unknown:
        return null;
    }
    throw ArgumentError.value(
      swelling,
      'swelling',
      'Invalid swelling value',
    );
  }
}

extension BloodPressureExtensions on BloodPressure {
  BloodPressureRequestBuilder toRequestBuilder() {
    final builder = BloodPressureRequestBuilder();

    builder.diastolicBloodPressure = diastolicBloodPressure;
    builder.systolicBloodPressure = systolicBloodPressure;
    builder.measuredAt = measuredAt;

    return builder;
  }

  String get formattedAmount {
    return '$formattedAmountWithoutDimension mmHg';
  }

  String get formattedAmountWithoutDimension {
    return '$systolicBloodPressure / $diastolicBloodPressure';
  }

  String formatAmountWithoutDimensionWithTime(BuildContext context) {
    final formattedTime =
        measuredAt.localDateTime.clockTime.formatHoursAndMinutes();

    return '$formattedAmountWithoutDimension ($formattedTime)';
  }
}

extension PulseExtensions on Pulse {
  PulseRequestBuilder toRequestBuilder() {
    final builder = PulseRequestBuilder();

    builder.pulse = pulse;
    builder.measuredAt = measuredAt;

    return builder;
  }

  String formattedAmount(AppLocalizations appLocalizations) {
    return '$pulse ${appLocalizations.pulseDimension}';
  }

  String formatAmountWithoutDimensionWithTime(BuildContext context) {
    final time = measuredAt.localDateTime.clockTime.formatHoursAndMinutes();

    return '$pulse ($time)';
  }
}

// Health indicators
extension DailyHealthStatusExtensions on DailyHealthStatus {
  bool isIndicatorExists(HealthIndicator indicator) {
    switch (indicator) {
      case HealthIndicator.bloodPressure:
        return bloodPressures.isNotEmpty;
      case HealthIndicator.pulse:
        return pulses.isNotEmpty;
      case HealthIndicator.weight:
        return weightKg != null;
      case HealthIndicator.glucose:
        return glucose != null;
      case HealthIndicator.urine:
        return urineMl != null;
      case HealthIndicator.severityOfSwelling:
        return swellingDifficulty != null &&
            swellingDifficulty != SwellingDifficultyEnum.unknown;
      case HealthIndicator.swellings:
        return swellings != null &&
            swellings
                .where((e) => e.swelling != SwellingEnum.unknown)
                .isNotEmpty;
      case HealthIndicator.wellBeing:
        return wellFeeling != null && wellFeeling != WellFeelingEnum.unknown;
      case HealthIndicator.appetite:
        return appetite != null && appetite != AppetiteEnum.unknown;
      case HealthIndicator.shortnessOfBreath:
        return shortnessOfBreath != null &&
            shortnessOfBreath != ShortnessOfBreathEnum.unknown;
    }
    throw ArgumentError.value(
      this,
      'healthIndicator',
      'Unable to map indicator and check for indicator existance',
    );
  }

  DailyHealthStatusRequest toRequest() {
    final builder = DailyHealthStatusRequestBuilder();

    builder.date = date;

    builder.weightKg = weightKg;
    builder.urineMl = urineMl;
    builder.glucose = glucose;

    builder.wellFeeling = wellFeeling;
    builder.shortnessOfBreath = shortnessOfBreath;
    builder.appetite = appetite;

    builder.swellingDifficulty = swellingDifficulty;

    final swellingRequests = swellings.map<SwellingRequest>((e) {
      final swellingBuilder = SwellingRequestBuilder();
      swellingBuilder.swelling = e.swelling;

      return swellingBuilder.build();
    }).toList();

    builder.swellings = ListBuilder(swellingRequests);

    return builder.build();
  }

  String getHealthIndicatorFormatted(
    HealthIndicator indicator,
    AppLocalizations appLocalizations,
  ) {
    if (!isIndicatorExists(indicator)) {
      return null;
    }

    switch (indicator) {
      case HealthIndicator.bloodPressure:
        final latestBloodPressure =
            bloodPressures.maxBy((_, p) => p.measuredAt.localDateTime);
        return '${latestBloodPressure.systolicBloodPressure} / ${latestBloodPressure.diastolicBloodPressure} mmHg';
      case HealthIndicator.pulse:
        final latestPulse = pulses.maxBy((_, p) => p.measuredAt.localDateTime);
        return '${latestPulse.pulse} ${appLocalizations.pulseDimension}';
      case HealthIndicator.weight:
        return '$weightKg kg';
      case HealthIndicator.glucose:
        return '${glucose.toStringAsFixed(2)} mmol/l';
      case HealthIndicator.urine:
        return _formatAmount(urineMl, 'ml');
      case HealthIndicator.severityOfSwelling:
        switch (swellingDifficulty) {
          case SwellingDifficultyEnum.n0plus:
            return '0+';
          case SwellingDifficultyEnum.n1plus:
            return '1+';
          case SwellingDifficultyEnum.n2plus:
            return '2+';
          case SwellingDifficultyEnum.n3plus:
            return '3+';
          case SwellingDifficultyEnum.n4plus:
            return '4+';
          case SwellingDifficultyEnum.unknown:
            return null;
        }
        throw ArgumentError.value(
          swellingDifficulty,
          'swellingDifficulty',
          'Invalid swellingDifficulty value',
        );
      case HealthIndicator.swellings:
        return getHealthIndicatorValue(indicator)?.toString();
      case HealthIndicator.wellBeing:
        switch (wellFeeling) {
          case WellFeelingEnum.perfect:
            return appLocalizations.healthStatusCreationWellFeelingPerfect;
          case WellFeelingEnum.good:
            return appLocalizations.healthStatusCreationWellFeelingGood;
          case WellFeelingEnum.average:
            return appLocalizations.healthStatusCreationWellFeelingAverage;
          case WellFeelingEnum.bad:
            return appLocalizations.healthStatusCreationWellFeelingBad;
          case WellFeelingEnum.veryBad:
            return appLocalizations.healthStatusCreationWellFeelingVeryBad;
          case WellFeelingEnum.unknown:
            return null;
        }
        throw ArgumentError.value(
          wellFeeling,
          'wellFeeling',
          'Invalid wellFeeling value',
        );
      case HealthIndicator.appetite:
        switch (appetite) {
          case AppetiteEnum.perfect:
            return appLocalizations.healthStatusCreationAppetitePerfect;
          case AppetiteEnum.good:
            return appLocalizations.healthStatusCreationAppetiteGood;
          case AppetiteEnum.average:
            return appLocalizations.healthStatusCreationAppetiteAverage;
          case AppetiteEnum.bad:
            return appLocalizations.healthStatusCreationAppetiteVeryBad;
          case AppetiteEnum.veryBad:
            return appLocalizations.healthStatusCreationAppetiteVeryBad;
          case AppetiteEnum.unknown:
            return null;
        }
        throw ArgumentError.value(
          appetite,
          'appetite',
          'Invalid appetite value',
        );
      case HealthIndicator.shortnessOfBreath:
        switch (shortnessOfBreath) {
          case ShortnessOfBreathEnum.no:
            return appLocalizations.healthStatusCreationShortnessOfBreathNo;
          case ShortnessOfBreathEnum.light:
            return appLocalizations.healthStatusCreationShortnessOfBreathLight;
          case ShortnessOfBreathEnum.average:
            return appLocalizations
                .healthStatusCreationShortnessOfBreathAverage;
          case ShortnessOfBreathEnum.severe:
            return appLocalizations.healthStatusCreationShortnessOfBreathSevere;
          case ShortnessOfBreathEnum.backbreaking:
            return appLocalizations
                .healthStatusCreationShortnessOfBreathBackbreaking;
          case ShortnessOfBreathEnum.unknown:
            return null;
        }
        throw ArgumentError.value(
          shortnessOfBreath,
          'shortnessOfBreath',
          'Invalid shortnessOfBreath value',
        );
    }
    throw ArgumentError.value(
      this,
      'healthIndicator',
      'Unable to map indicator to formatted indicator',
    );
  }

  num getHealthIndicatorValue(HealthIndicator indicator) {
    if (!isIndicatorExists(indicator)) {
      return null;
    }

    switch (indicator) {
      case HealthIndicator.bloodPressure:
        throw ArgumentError(
            'Unable to get blood pressure indicator value. Please use different method');
      case HealthIndicator.pulse:
        return pulses.maxBy((_, p) => p.measuredAt.localDateTime).pulse;
      case HealthIndicator.weight:
        return weightKg;
      case HealthIndicator.glucose:
        return glucose;
      case HealthIndicator.urine:
        return urineMl;
      case HealthIndicator.severityOfSwelling:
        switch (swellingDifficulty) {
          case SwellingDifficultyEnum.n0plus:
            return 0;
          case SwellingDifficultyEnum.n1plus:
            return 1;
          case SwellingDifficultyEnum.n2plus:
            return 2;
          case SwellingDifficultyEnum.n3plus:
            return 3;
          case SwellingDifficultyEnum.n4plus:
            return 4;
          case SwellingDifficultyEnum.unknown:
            return null;
        }
        throw ArgumentError.value(
          swellingDifficulty,
          'swellingDifficulty',
          'Invalid swellingDifficulty value',
        );
      case HealthIndicator.swellings:
        return swellings
            .where((e) => e.swelling != SwellingEnum.unknown)
            .length;
      case HealthIndicator.wellBeing:
        switch (wellFeeling) {
          case WellFeelingEnum.perfect:
            return 1;
          case WellFeelingEnum.good:
            return 2;
          case WellFeelingEnum.average:
            return 3;
          case WellFeelingEnum.bad:
            return 4;
          case WellFeelingEnum.veryBad:
            return 5;
          case WellFeelingEnum.unknown:
            return null;
        }
        throw ArgumentError.value(
          wellFeeling,
          'wellFeeling',
          'Invalid wellFeeling value',
        );
      case HealthIndicator.appetite:
        switch (appetite) {
          case AppetiteEnum.perfect:
            return 1;
          case AppetiteEnum.good:
            return 2;
          case AppetiteEnum.average:
            return 3;
          case AppetiteEnum.bad:
            return 4;
          case AppetiteEnum.veryBad:
            return 5;
          case AppetiteEnum.unknown:
            return null;
        }
        throw ArgumentError.value(
          appetite,
          'appetite',
          'Invalid appetite value',
        );
      case HealthIndicator.shortnessOfBreath:
        switch (shortnessOfBreath) {
          case ShortnessOfBreathEnum.no:
            return 1;
          case ShortnessOfBreathEnum.light:
            return 2;
          case ShortnessOfBreathEnum.average:
            return 3;
          case ShortnessOfBreathEnum.severe:
            return 4;
          case ShortnessOfBreathEnum.backbreaking:
            return 5;
          case ShortnessOfBreathEnum.unknown:
            return null;
        }
        throw ArgumentError.value(
          shortnessOfBreath,
          'shortnessOfBreath',
          'Invalid shortnessOfBreath value',
        );
    }
    throw ArgumentError.value(
      this,
      'healthIndicator',
      'Unable to map indicator to formatted indicator',
    );
  }

  int get totalManualPeritonealDialysisBalance =>
      manualPeritonealDialysis.sumBy((_, d) => d.balance);

  String get totalManualPeritonealDialysisBalanceFormatted =>
      _formatAmount(totalManualPeritonealDialysisBalance, 'ml');
}

extension HealthIndicatorExtensions on HealthIndicator {
  String name(AppLocalizations appLocalizations) {
    switch (this) {
      case HealthIndicator.bloodPressure:
        return appLocalizations.healthStatusCreationBloodPressure;
      case HealthIndicator.pulse:
        return appLocalizations.pulse;
      case HealthIndicator.weight:
        return appLocalizations.weight;
      case HealthIndicator.glucose:
        return appLocalizations.healthStatusCreationGlucose;
      case HealthIndicator.urine:
        return appLocalizations.healthStatusCreationUrine;
      case HealthIndicator.severityOfSwelling:
        return appLocalizations.healthStatusCreationSwellingDifficulty;
      case HealthIndicator.swellings:
        return appLocalizations.healthStatusCreationSwellings;
      case HealthIndicator.wellBeing:
        return appLocalizations.healthStatusCreationWellFeeling;
      case HealthIndicator.appetite:
        return appLocalizations.healthStatusCreationAppetite;
      case HealthIndicator.shortnessOfBreath:
        return appLocalizations.healthStatusCreationShortnessOfBreath;
    }
    throw ArgumentError.value(
      this,
      'healthIndicator',
      'Unable to map indicator to name',
    );
  }

  bool get isMultiValuesPerDay {
    switch (this) {
      case HealthIndicator.bloodPressure:
      case HealthIndicator.pulse:
        return true;
      case HealthIndicator.weight:
      case HealthIndicator.glucose:
      case HealthIndicator.urine:
      case HealthIndicator.severityOfSwelling:
      case HealthIndicator.swellings:
      case HealthIndicator.wellBeing:
      case HealthIndicator.appetite:
      case HealthIndicator.shortnessOfBreath:
        return false;
    }
    throw ArgumentError.value(
      this,
      'healthIndicator',
      'Unable to map indicator to isMultiValuesPerDay',
    );
  }

  int get decimalPlaces {
    switch (this) {
      case HealthIndicator.bloodPressure:
      case HealthIndicator.pulse:
        return 0;
      case HealthIndicator.weight:
        return 1;
      case HealthIndicator.glucose:
        return 2;
      case HealthIndicator.urine:
        return 1;
      case HealthIndicator.severityOfSwelling:
      case HealthIndicator.swellings:
      case HealthIndicator.wellBeing:
      case HealthIndicator.appetite:
      case HealthIndicator.shortnessOfBreath:
        return 1;
    }
    throw ArgumentError.value(
      this,
      'healthIndicator',
      'Unable to map indicator to name',
    );
  }

  String dimension(AppLocalizations appLocalizations) {
    switch (this) {
      case HealthIndicator.bloodPressure:
        return 'mmHg';
      case HealthIndicator.pulse:
        return appLocalizations.pulseDimension;
      case HealthIndicator.weight:
        return 'kg';
      case HealthIndicator.glucose:
        return 'mmol/l';
      case HealthIndicator.urine:
        return 'ml';
      case HealthIndicator.severityOfSwelling:
      case HealthIndicator.swellings:
      case HealthIndicator.wellBeing:
      case HealthIndicator.appetite:
      case HealthIndicator.shortnessOfBreath:
        return null;
    }
    throw ArgumentError.value(
      this,
      'healthIndicator',
      'Unable to map indicator to name',
    );
  }
}

extension DialysisSolutionExtension on DialysisSolutionEnum {
  String localizedName(AppLocalizations appLocalizations) {
    switch (this) {
      case DialysisSolutionEnum.green:
        return appLocalizations.dialysisSolutionGreen;
      case DialysisSolutionEnum.yellow:
        return appLocalizations.dialysisSolutionYellow;

      case DialysisSolutionEnum.orange:
        return appLocalizations.dialysisSolutionOrange;

      case DialysisSolutionEnum.blue:
        return appLocalizations.dialysisSolutionBlue;

      case DialysisSolutionEnum.purple:
        return appLocalizations.dialysisSolutionPurple;

      case DialysisSolutionEnum.unknown:
        return appLocalizations.unknown;
    }

    throw ArgumentError.value(this);
  }

  String localizedDescription(AppLocalizations appLocalizations) {
    switch (this) {
      case DialysisSolutionEnum.green:
        return appLocalizations.dialysisSolutionGreenDescription;
      case DialysisSolutionEnum.yellow:
        return appLocalizations.dialysisSolutionYellowDescription;

      case DialysisSolutionEnum.orange:
        return appLocalizations.dialysisSolutionOrangeDescription;

      case DialysisSolutionEnum.blue:
        return appLocalizations.dialysisSolutionBlueDescription;

      case DialysisSolutionEnum.purple:
        return appLocalizations.dialysisSolutionPurpleDescription;

      case DialysisSolutionEnum.unknown:
        return appLocalizations.unknown;
    }

    throw ArgumentError.value(this);
  }

  Color get color {
    switch (this) {
      case DialysisSolutionEnum.green:
        return Colors.green;
      case DialysisSolutionEnum.yellow:
        return Colors.yellow;
      case DialysisSolutionEnum.orange:
        return Colors.orange;
      case DialysisSolutionEnum.blue:
        return Colors.blue;
      case DialysisSolutionEnum.purple:
        return Colors.purple;
      case DialysisSolutionEnum.unknown:
        return Colors.black;
    }

    throw ArgumentError.value(this);
  }

  Color get textColor {
    switch (this) {
      case DialysisSolutionEnum.yellow:
        return Colors.black;
      case DialysisSolutionEnum.green:
      case DialysisSolutionEnum.orange:
      case DialysisSolutionEnum.blue:
      case DialysisSolutionEnum.purple:
      case DialysisSolutionEnum.unknown:
        return Colors.white;
    }

    throw ArgumentError.value(this);
  }
}

extension DialysateColorExtensions on DialysateColorEnum {
  String localizedName(AppLocalizations appLocalizations) {
    switch (this) {
      case DialysateColorEnum.transparent:
        return appLocalizations.dialysateColorTransparent;
      case DialysateColorEnum.pink:
        return appLocalizations.dialysateColorPink;

      case DialysateColorEnum.cloudyYellowish:
        return appLocalizations.dialysateColorCloudyYellowish;

      case DialysateColorEnum.greenish:
        return appLocalizations.dialysateColorGreenish;

      case DialysateColorEnum.brown:
        return appLocalizations.dialysateColorBrown;

      case DialysateColorEnum.cloudyWhite:
        return appLocalizations.dialysateColorCloudyWhite;

      case DialysateColorEnum.unknown:
        return appLocalizations.unknown;
    }

    throw ArgumentError.value(this);
  }

  Color get color {
    switch (this) {
      case DialysateColorEnum.transparent:
        return Colors.transparent;
      case DialysateColorEnum.pink:
        return Colors.pink;
      case DialysateColorEnum.cloudyYellowish:
        return Colors.yellowAccent;
      case DialysateColorEnum.greenish:
        return Colors.lightGreen;
      case DialysateColorEnum.brown:
        return Colors.brown;
      case DialysateColorEnum.cloudyWhite:
        return Colors.grey;
      case DialysateColorEnum.unknown:
        return Colors.black;
    }

    throw ArgumentError.value(this);
  }

  Color get textColor {
    switch (this) {
      case DialysateColorEnum.transparent:
      case DialysateColorEnum.cloudyWhite:
      case DialysateColorEnum.cloudyYellowish:
        return Colors.black;
      case DialysateColorEnum.pink:
      case DialysateColorEnum.greenish:
      case DialysateColorEnum.brown:
      case DialysateColorEnum.unknown:
        return Colors.white;
    }

    throw ArgumentError.value(this);
  }
}

extension ManualPeritonealDialysisExtensions on ManualPeritonealDialysis {
  int get balance => solutionOutMl != null ? solutionInMl - solutionOutMl : 0;

  ManualPeritonealDialysisRequestBuilder toRequestBuilder() {
    final builder = ManualPeritonealDialysisRequestBuilder();

    builder.isCompleted = isCompleted;
    builder.startedAt = startedAt;
    builder.dialysisSolution = dialysisSolution;
    builder.solutionInMl = solutionInMl;
    builder.solutionOutMl = solutionOutMl;
    builder.dialysateColor = dialysateColor;
    builder.notes = notes;
    builder.finishedAt = finishedAt;

    return builder;
  }

  String get formattedBalance {
    return _formatAmount(balance, 'ml');
  }

  String get formattedSolutionIn {
    return _formatAmount(solutionInMl, 'ml');
  }

  String get formattedSolutionOut {
    if (solutionOutMl == null) {
      return '-';
    }
    return _formatAmount(solutionOutMl, 'ml');
  }
}

extension AutomaticPeritonealDialysisExtensions on AutomaticPeritonealDialysis {
  AutomaticPeritonealDialysisRequestBuilder toRequestBuilder() {
    final builder = AutomaticPeritonealDialysisRequestBuilder();

    builder.isCompleted = isCompleted;
    builder.startedAt = startedAt;

    builder.solutionBlueInMl = solutionBlueInMl;
    builder.solutionGreenInMl = solutionGreenInMl;
    builder.solutionOrangeInMl = solutionOrangeInMl;
    builder.solutionPurpleInMl = solutionPurpleInMl;
    builder.solutionYellowInMl = solutionYellowInMl;

    builder.initialDrainingMl = initialDrainingMl;
    builder.totalDrainVolumeMl = totalDrainVolumeMl;
    builder.lastFillMl = lastFillMl;
    builder.totalUltrafiltrationMl = totalUltrafiltrationMl;
    builder.additionalDrainMl = additionalDrainMl;

    builder.dialysateColor = dialysateColor;

    builder.notes = notes;
    builder.finishedAt = finishedAt;

    return builder;
  }

  int get balance {
    if (totalUltrafiltrationMl == null) {
      return null;
    }

    final totalLiquidsMl =
        dailyIntakesLightReport.nutrientNormsAndTotals.liquidsMl.total;
    final totalUrineMl = dailyHealthStatus.urineMl ?? 0;

    return totalLiquidsMl - totalUltrafiltrationMl - totalUrineMl;
  }

  String get formattedBalance {
    if (balance == null) {
      return null;
    }

    return _formatAmount(balance, 'ml');
  }
}

extension EnumClassExtensions<E extends EnumClass> on E {
  E enumWithoutDefault(E defaultValue) => (this == defaultValue) ? null : this;
}
