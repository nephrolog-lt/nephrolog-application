import 'package:flutter/material.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/ui/forms/form_validators.dart';
import 'package:nephrogo/ui/forms/forms.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/general/dialogs.dart';
import 'package:nephrogo/ui/general/progress_dialog.dart';
import 'package:nephrogo_api_client/model/blood_pressure.dart';
import 'package:nephrogo_api_client/model/blood_pressure_request.dart';
import 'package:nephrogo_api_client/model/pulse.dart';
import 'package:nephrogo_api_client/model/pulse_request.dart';

class BloodPressureAndPulseCreationScreen extends StatefulWidget {
  @override
  _BloodPressureAndPulseCreationScreenState createState() =>
      _BloodPressureAndPulseCreationScreenState();
}

class _BloodPressureAndPulseCreationScreenState
    extends State<BloodPressureAndPulseCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _apiService = ApiService();

  DateTime _measuredAt;
  int _systolicBloodPressure;
  int _diastolicBloodPressure;
  int _pulse;

  FormValidators get _formValidators => FormValidators(context);

  bool get _isPulsePresent => _pulse != null;

  bool get _isBloodPressurePresent =>
      _systolicBloodPressure != null && _diastolicBloodPressure != null;

  @override
  void initState() {
    super.initState();

    _measuredAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.bloodPressureAndPulse),
        actions: <Widget>[
          AppBarTextButton(
            onPressed: _submit,
            child: Text(appLocalizations.save.toUpperCase()),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            SmallSection(
              title: appLocalizations.measureDateAndTime,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AppDatePickerFormField(
                        initialDate: _measuredAt,
                        selectedDate: _measuredAt,
                        firstDate: DateTime(2021),
                        lastDate: DateTime.now(),
                        validator: _formValidators.nonNull(),
                        onDateChanged: (dt) {
                          final ldt = dt.toLocal();
                          _measuredAt = DateTime(
                            ldt.year,
                            ldt.month,
                            ldt.day,
                            _measuredAt.hour,
                            _measuredAt.minute,
                          );
                        },
                        labelText: appLocalizations.mealCreationDate,
                      ),
                    ),
                    Flexible(
                      child: AppTimePickerFormField(
                        initialTime: TimeOfDay.fromDateTime(_measuredAt),
                        labelText: appLocalizations.mealCreationTime,
                        onTimeChanged: (t) =>
                            _measuredAt = _measuredAt.applied(t),
                        onTimeSaved: (t) =>
                            _measuredAt = _measuredAt.applied(t),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SmallSection(
              title: appLocalizations.healthStatusCreationBloodPressure,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: AppIntegerFormField(
                        labelText:
                            appLocalizations.healthStatusCreationSystolic,
                        suffixText: 'mmHg',
                        validator: _formValidators.numRangeValidator(1, 350),
                        textInputAction: TextInputAction.next,
                        initialValue: _systolicBloodPressure,
                        onChanged: (value) => _systolicBloodPressure = value,
                      ),
                    ),
                    Flexible(
                      child: AppIntegerFormField(
                        labelText:
                            appLocalizations.healthStatusCreationDiastolic,
                        suffixText: 'mmHg',
                        validator: _formValidators.numRangeValidator(1, 200),
                        textInputAction: TextInputAction.next,
                        initialValue: _diastolicBloodPressure,
                        onChanged: (value) => _diastolicBloodPressure = value,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Text(
                    appLocalizations.healthStatusCreationBloodPressureHelper,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
            SmallSection(
              title: appLocalizations.pulse,
              children: [
                AppIntegerFormField(
                  labelText: appLocalizations.pulse,
                  suffixText: appLocalizations.pulseDimension,
                  validator: _formValidators.numRangeValidator(10, 200),
                  initialValue: _pulse,
                  onChanged: (p) => _pulse = p,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<BloodPressure> _saveBloodPressure() {
    final builder = BloodPressureRequestBuilder();
    builder.diastolicBloodPressure = _diastolicBloodPressure;
    builder.systolicBloodPressure = _systolicBloodPressure;
    builder.measuredAt = _measuredAt.toUtc();

    final bloodPressureRequest = builder.build();

    return _apiService.createBloodPressure(bloodPressureRequest);
  }

  Future<Pulse> _savePulse() {
    final builder = PulseRequestBuilder();
    builder.pulse = _pulse;
    builder.measuredAt = _measuredAt.toUtc();

    final pulseRequest = builder.build();

    return _apiService.createPulse(pulseRequest);
  }

  Future<bool> _save() async {
    if (_isPulsePresent) {
      await _savePulse();
    }

    if (_isBloodPressurePresent) {
      await _saveBloodPressure();
    }

    return true;
  }

  Future _submit() async {
    if (!_formKey.currentState.validate()) {
      await showAppDialog(
        context: context,
        title: appLocalizations.error,
        message: appLocalizations.formErrorDescription,
      );

      return false;
    }
    _formKey.currentState.save();

    final savingFuture = _save().catchError(
      (e, stackTrace) async {
        await showAppDialog(
          context: context,
          title: appLocalizations.error,
          message: appLocalizations.serverErrorDescription,
        );
      },
    );

    final res = await ProgressDialog(context).showForFuture(savingFuture);

    if (res != null) {
      Navigator.pop(context);
    }
  }
}