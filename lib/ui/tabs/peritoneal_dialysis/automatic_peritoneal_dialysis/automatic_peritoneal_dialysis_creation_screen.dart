import 'package:flutter/material.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/constants.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/ui/forms/form_validators.dart';
import 'package:nephrogo/ui/forms/forms.dart';
import 'package:nephrogo/ui/general/buttons.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/general/dialogs.dart';
import 'package:nephrogo/ui/general/stepper.dart';
import 'package:nephrogo/ui/tabs/peritoneal_dialysis/peritoneal_dialysis_components.dart';
import 'package:nephrogo/utils/form_utils.dart';
import 'package:nephrogo_api_client/model/automatic_peritoneal_dialysis.dart';
import 'package:nephrogo_api_client/model/automatic_peritoneal_dialysis_request.dart';
import 'package:nephrogo_api_client/model/dialysate_color_enum.dart';
import 'package:nephrogo_api_client/model/dialysis_solution_enum.dart';
import 'package:time_machine/time_machine.dart';

class AutomaticPeritonealDialysisCreationScreenArguments {
  final AutomaticPeritonealDialysis dialysis;

  AutomaticPeritonealDialysisCreationScreenArguments(this.dialysis);
}

class AutomaticPeritonealDialysisCreationScreen extends StatefulWidget {
  final AutomaticPeritonealDialysis initialDialysis;

  const AutomaticPeritonealDialysisCreationScreen({
    Key key,
    @required this.initialDialysis,
  }) : super(key: key);

  @override
  _AutomaticPeritonealDialysisCreationScreenState createState() =>
      _AutomaticPeritonealDialysisCreationScreenState();
}

class _AutomaticPeritonealDialysisCreationScreenState
    extends State<AutomaticPeritonealDialysisCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _apiService = ApiService();

  final now = LocalDateTime.now();
  final today = LocalDate.today();

  AutomaticPeritonealDialysisRequestBuilder _requestBuilder;

  int _currentStep = 0;

  bool get _isSecondStep => _currentStep == 1;

  FormValidators get _formValidators => FormValidators(context);

  bool get _isCompleted => widget.initialDialysis?.isCompleted ?? false;

  @override
  void initState() {
    super.initState();

    _requestBuilder = widget.initialDialysis?.toRequestBuilder() ??
        AutomaticPeritonealDialysisRequestBuilder();

    _requestBuilder.startedAt ??= now.withOffset(Offset.zero);
    _currentStep = _requestBuilder.isCompleted == false ? 1 : 0;

    _requestBuilder.isCompleted ??= false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.peritonealDialysis),
        actions: <Widget>[
          if (_isSecondStep)
            AppBarTextButton(
              onPressed: _completeAndSubmit,
              child: Text(appLocalizations.finish.toUpperCase()),
            )
          else
            AppBarTextButton(
              onPressed: _submit,
              child: Text(appLocalizations.save.toUpperCase()),
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: AppStepper(
          type: AppStepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: _validateAndProceedToStep,
          onStepContinue: () async {
            if (_currentStep == 0) {
              await _validateAndProceedToStep(_currentStep + 1);
            } else {
              await _completeAndSubmit();
            }
          },
          onStepCancel: _submit,
          controlsBuilder: (context, {onStepContinue, onStepCancel}) {
            if (_isSecondStep) {
              return BasicSection(
                innerPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: AppElevatedButton(
                        text: context.appLocalizations.finishDialysis,
                        onPressed: onStepContinue,
                      ),
                    ),
                  ),
                  if (_isCompleted)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: AppElevatedButton(
                          color: Colors.redAccent,
                          text: context.appLocalizations.delete,
                          onPressed: _delete,
                        ),
                      ),
                    ),
                ],
              );
            }
            return BasicSection(
              innerPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                if (widget.initialDialysis == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: AppElevatedButton(
                        text: context.appLocalizations.saveAndContinueLater,
                        onPressed: onStepCancel,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppElevatedButton(
                      color: Colors.blue,
                      text: context.appLocalizations.continueToSecondStep,
                      onPressed: onStepContinue,
                    ),
                  ),
                ),
                if (_isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: AppElevatedButton(
                        color: Colors.redAccent,
                        text: context.appLocalizations.delete,
                        onPressed: _delete,
                      ),
                    ),
                  ),
              ],
            );
          },
          steps: [
            AppStep(
              title: Text(appLocalizations.manualPeritonealDialysisStep1),
              isActive: _currentStep == 0,
              state: _currentStep == 0 ? StepState.indexed : StepState.complete,
              content: _getFirstStep(),
            ),
            AppStep(
              title: Text(appLocalizations.manualPeritonealDialysisStep2),
              isActive: _currentStep == 1,
              state: _isCompleted && _currentStep != 1
                  ? StepState.complete
                  : StepState.indexed,
              content: _getSecondStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getFirstStep() {
    return Column(
      children: [
        SmallSection(
          title: appLocalizations.dialysisStartDateTime,
          children: [
            Row(
              children: [
                Flexible(
                  flex: 3,
                  child: AppDatePickerFormField(
                    initialDate: _requestBuilder.startedAt.calendarDate,
                    selectedDate: _requestBuilder.startedAt.calendarDate,
                    firstDate: Constants.earliestDate,
                    lastDate: today,
                    validator: _formValidators.nonNull(),
                    onDateChanged: (date) {
                      _requestBuilder.startedAt =
                          _requestBuilder.startedAt.adjustDate((_) => date);
                    },
                    labelText: appLocalizations.date,
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: AppTimePickerFormField(
                    initialTime: _requestBuilder.startedAt.clockTime,
                    labelText: appLocalizations.mealCreationTime,
                    onTimeChanged: (time) => _requestBuilder.startedAt =
                        _requestBuilder.startedAt.adjustTime((_) => time),
                    onTimeSaved: (time) => _requestBuilder.startedAt =
                        _requestBuilder.startedAt.adjustTime((_) => time),
                  ),
                ),
              ],
            ),
          ],
        ),
        SmallSection(
          title: appLocalizations.dialysisSolutionVolumes,
          children: [
            AppIntegerFormField(
              icon: const DialysisSolutionAvatar(
                dialysisSolution: DialysisSolutionEnum.yellow,
              ),
              labelText: appLocalizations.dialysisSolutionYellow,
              helperText: appLocalizations.dialysisSolutionYellowDescription,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.numRangeValidator(1, 10000),
              initialValue: _requestBuilder.solutionYellowInMl != 0
                  ? _requestBuilder.solutionYellowInMl
                  : null,
              onChanged: (p) => _requestBuilder.solutionYellowInMl = p,
            ),
            AppIntegerFormField(
              icon: const DialysisSolutionAvatar(
                dialysisSolution: DialysisSolutionEnum.green,
              ),
              labelText: appLocalizations.dialysisSolutionGreen,
              helperText: appLocalizations.dialysisSolutionGreenDescription,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.numRangeValidator(1, 10000),
              initialValue: _requestBuilder.solutionGreenInMl != 0
                  ? _requestBuilder.solutionGreenInMl
                  : null,
              onChanged: (p) => _requestBuilder.solutionGreenInMl = p,
            ),
            AppIntegerFormField(
              icon: const DialysisSolutionAvatar(
                dialysisSolution: DialysisSolutionEnum.orange,
              ),
              labelText: appLocalizations.dialysisSolutionOrange,
              helperText: appLocalizations.dialysisSolutionOrangeDescription,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.numRangeValidator(1, 10000),
              initialValue: _requestBuilder.solutionOrangeInMl != 0
                  ? _requestBuilder.solutionOrangeInMl
                  : null,
              onChanged: (p) => _requestBuilder.solutionOrangeInMl = p,
            ),
            AppIntegerFormField(
              icon: const DialysisSolutionAvatar(
                dialysisSolution: DialysisSolutionEnum.blue,
              ),
              labelText: appLocalizations.dialysisSolutionBlue,
              helperText: appLocalizations.dialysisSolutionBlueDescription,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.numRangeValidator(1, 10000),
              initialValue: _requestBuilder.solutionBlueInMl != 0
                  ? _requestBuilder.solutionBlueInMl
                  : null,
              onChanged: (p) => _requestBuilder.solutionBlueInMl = p,
            ),
            AppIntegerFormField(
              icon: const DialysisSolutionAvatar(
                dialysisSolution: DialysisSolutionEnum.purple,
              ),
              labelText: appLocalizations.dialysisSolutionPurple,
              helperText: appLocalizations.dialysisSolutionPurpleDescription,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.numRangeValidator(1, 10000),
              initialValue: _requestBuilder.solutionPurpleInMl != 0
                  ? _requestBuilder.solutionPurpleInMl
                  : null,
              onChanged: (p) => _requestBuilder.solutionPurpleInMl = p,
            ),
          ],
        ),
      ],
    );
  }

  Widget _getSecondStep() {
    return Column(
      children: [
        SmallSection(
          title: appLocalizations.machineReadings,
          children: [
            AppIntegerFormField(
              labelText: appLocalizations.initialDraining,
              helperText: appLocalizations.initialDrainingHelper,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.and(
                _formValidators.nonNull(),
                _formValidators.numRangeValidator(1, 10000),
              ),
              initialValue: _requestBuilder.initialDrainingMl,
              onChanged: (p) => _requestBuilder.initialDrainingMl = p,
            ),
            AppIntegerFormField(
              labelText: appLocalizations.totalDrainVolume,
              helperText: appLocalizations.totalDrainVolumeHelper,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.and(
                _formValidators.nonNull(),
                _formValidators.numRangeValidator(1, 10000),
              ),
              initialValue: _requestBuilder.totalDrainVolumeMl,
              onChanged: (p) => _requestBuilder.totalDrainVolumeMl = p,
            ),
            AppIntegerFormField(
              labelText: appLocalizations.lastFill,
              helperText: appLocalizations.lastFillHelper,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.and(
                _formValidators.nonNull(),
                _formValidators.numRangeValidator(1, 10000),
              ),
              initialValue: _requestBuilder.lastFillMl,
              onChanged: (p) => _requestBuilder.lastFillMl = p,
            ),
            AppIntegerFormField(
              labelText: appLocalizations.totalUltraFiltration,
              helperText: appLocalizations.totalUltraFiltrationHelper,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.and(
                _formValidators.nonNull(),
                _formValidators.numRangeValidator(1, 10000),
              ),
              initialValue: _requestBuilder.totalUltrafiltrationMl,
              onChanged: (p) => _requestBuilder.totalUltrafiltrationMl = p,
            ),
          ],
        ),
        SmallSection(
          title: appLocalizations.additionalDrainSectionTitle,
          children: [
            AppIntegerFormField(
              labelText: appLocalizations.additionalDrain,
              helperText: appLocalizations.additionalDrainHelper,
              suffixText: 'ml',
              textInputAction: TextInputAction.next,
              validator: _formValidators.numRangeValidator(1, 10000),
              initialValue: _requestBuilder.additionalDrainMl,
              onChanged: (p) => _requestBuilder.additionalDrainMl = p,
            ),
          ],
        ),
        SmallSection(
          title: appLocalizations.dialysate,
          children: [
            AppSelectFormField<DialysateColorEnum>(
              labelText: appLocalizations.dialysateColor,
              initialValue: _requestBuilder.dialysateColor
                      ?.enumWithoutDefault(DialysateColorEnum.unknown) ??
                  DialysateColorEnum.transparent,
              focusNextOnSelection: true,
              onChanged: (v) => _requestBuilder.dialysateColor = v?.value,
              onSaved: (v) {
                if (_isSecondStep) {
                  _requestBuilder.dialysateColor = v?.value;
                }
              },
              items: [
                for (final color in DialysateColorEnum.values
                    .where((v) => v != DialysateColorEnum.unknown))
                  AppSelectFormFieldItem(
                    text: color.localizedName(appLocalizations),
                    icon: Icon(Icons.circle, color: color.color),
                    value: color,
                  ),
              ],
            ),
          ],
        ),
        SmallSection(
          title: appLocalizations.dialysisEndDateTime,
          children: [
            Row(
              children: [
                Flexible(
                  flex: 3,
                  child: AppDatePickerFormField(
                    initialDate:
                        _requestBuilder.finishedAt?.calendarDate ?? today,
                    selectedDate:
                        _requestBuilder.finishedAt?.calendarDate ?? today,
                    firstDate: _requestBuilder.startedAt.calendarDate,
                    lastDate: today,
                    validator: _formValidators.nonNull(),
                    onDateChanged: (date) {
                      _requestBuilder.finishedAt =
                          _requestBuilder.finishedAt.adjustDate((_) => date);
                    },
                    labelText: appLocalizations.date,
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: AppTimePickerFormField(
                    initialTime:
                        _requestBuilder.finishedAt?.clockTime ?? now.clockTime,
                    labelText: appLocalizations.mealCreationTime,
                    onTimeChanged: (time) {
                      _requestBuilder.finishedAt ??=
                          now.withOffset(Offset.zero);

                      _requestBuilder.finishedAt =
                          _requestBuilder.finishedAt.adjustTime((_) => time);
                    },
                    onTimeSaved: (time) {
                      if (_isSecondStep) {
                        _requestBuilder.finishedAt ??=
                            now.withOffset(Offset.zero);

                        _requestBuilder.finishedAt =
                            _requestBuilder.finishedAt.adjustTime((_) => time);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        SmallSection(
          title: appLocalizations.notes,
          children: [
            AppTextFormField(
              textCapitalization: TextCapitalization.sentences,
              labelText: appLocalizations.notes,
              initialValue: _requestBuilder.notes,
              textInputAction: TextInputAction.next,
              onChanged: (s) => _requestBuilder.notes = s,
              onSaved: (s) => _requestBuilder.notes = s,
              maxLines: 3,
            ),
          ],
        ),
      ],
    );
  }

  Future<AutomaticPeritonealDialysis> _save() {
    final request = _requestBuilder.build();

    if (widget.initialDialysis == null) {
      return _apiService.createAutomaticPeritonealDialysis(request);
    }

    return _apiService.updateAutomaticPeritonealDialysis(
      widget.initialDialysis.date.calendarDate,
      request,
    );
  }

  Future<bool> _completeAndSubmit() {
    _requestBuilder.isCompleted = true;

    return _submit();
  }

  Future<bool> _submit() {
    return FormUtils.validateAndSave(
      context: context,
      formKey: _formKey,
      futureBuilder: _save,
    );
  }

  Future<bool> _validateAndProceedToStep(int step) async {
    final valid = await FormUtils.validate(
      context: context,
      formKey: _formKey,
    );

    if (valid) {
      setState(() => _currentStep = step);
      return true;
    }
    return false;
  }

  Future<void> _delete() async {
    final isDeleted = await showDeleteDialog(
      context: context,
      onDelete: () => _apiService.deleteAutomaticPeritonealDialysis(
        widget.initialDialysis.date.calendarDate,
      ),
    );

    if (isDeleted) {
      Navigator.pop(context);
    }
  }
}
