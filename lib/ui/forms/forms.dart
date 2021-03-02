import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:time_machine/time_machine.dart';

import 'app_form_multi_select_dialog.dart';
import 'app_form_single_select_dialog.dart';

typedef FormFieldItemSetter<T> = void Function(T newItem);

class AppDropdownMenuItem<T> {
  final Key key;
  final String text;
  final T value;

  AppDropdownMenuItem({this.key, @required this.text, @required this.value});
}

const _defaultFieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

class AppTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final String helperText;
  final String hintText;
  final String initialValue;
  final Widget icon;
  final Widget prefixIcon;
  final FormFieldValidator<String> validator;
  final FormFieldSetter<String> onSaved;
  final FormFieldSetter<String> onChanged;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String suffixText;
  final GestureTapCallback onTap;
  final EdgeInsets padding;
  final bool disabled;
  final bool autoFocus;
  final Widget suffixIcon;
  final bool obscureText;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final VoidCallback onEditingComplete;
  final ValueChanged<String> onFieldSubmitted;
  final int maxLines;
  final TextCapitalization textCapitalization;

  const AppTextFormField({
    Key key,
    @required this.labelText,
    this.onSaved,
    this.onChanged,
    this.helperText,
    this.hintText,
    this.icon,
    this.prefixIcon,
    this.validator,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.suffixText,
    this.onTap,
    this.initialValue,
    this.suffixIcon,
    this.padding = _defaultFieldPadding,
    this.autoFocus = false,
    this.disabled = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.autofillHints,
    this.textInputAction,
    this.focusNode,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          helperText: helperText,
          suffixText: suffixText,
          hintText: hintText,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
          icon: icon,
        ),
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        controller: controller,
        initialValue: initialValue,
        readOnly: disabled,
        autofocus: autoFocus,
        enableInteractiveSelection: !disabled,
        autofillHints: autofillHints,
        obscureText: obscureText,
        onTap: onTap,
        maxLines: maxLines,
        textInputAction: textInputAction,
        onEditingComplete: onEditingComplete,
        onFieldSubmitted: onFieldSubmitted,
        textCapitalization: textCapitalization,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}

class AppSelectFormFieldItem<T> {
  final String text;
  final String description;
  final Widget icon;
  final T value;

  const AppSelectFormFieldItem({
    @required this.text,
    this.description,
    this.icon,
    @required this.value,
  });
}

class AppSelectionScreenFormField<T> extends StatefulWidget {
  final String labelText;
  final String helperText;
  final T initialSelection;
  final String Function(T item) itemToStringConverter;
  final Future<T> Function(BuildContext context) onTap;
  final Widget icon;
  final Widget prefixIcon;
  final FormFieldItemSetter<T> onChanged;
  final FormFieldItemSetter<T> onSaved;
  final FormFieldValidator<T> validator;

  const AppSelectionScreenFormField({
    Key key,
    @required this.onTap,
    @required this.itemToStringConverter,
    this.labelText,
    this.helperText,
    this.initialSelection,
    this.icon,
    this.prefixIcon,
    this.onChanged,
    this.onSaved,
    this.validator,
  }) : super(key: key);

  @override
  _AppSelectionScreenFormFieldState createState() =>
      _AppSelectionScreenFormFieldState<T>();
}

class _AppSelectionScreenFormFieldState<T>
    extends State<AppSelectionScreenFormField<T>> {
  final TextEditingController _textEditingController = TextEditingController();
  T _selectedItem;

  @override
  void initState() {
    super.initState();

    if (widget.initialSelection != null) {
      _setItem(widget.initialSelection, initial: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      labelText: widget.labelText,
      controller: _textEditingController,
      helperText: widget.helperText,
      icon: widget.icon,
      prefixIcon: widget.prefixIcon,
      disabled: true,
      onTap: () => _onTap(context),
      suffixIcon: const Icon(Icons.chevron_right),
      onSaved: _onSaved,
      validator: _validator,
    );
  }

  String _validator(String value) {
    if (widget.validator != null) {
      return widget.validator(_selectedItem);
    }
    return null;
  }

  void _onSaved(String s) {
    if (widget.onSaved != null) {
      widget.onSaved(_selectedItem);
    }
  }

  Future _onTap(BuildContext context) async {
    final selectedItem = await widget.onTap(context);

    if (selectedItem != null) {
      _setItem(selectedItem);
    }
  }

  void _setItem(T item, {bool initial = false}) {
    _selectedItem = item;
    _textEditingController.text = widget.itemToStringConverter(_selectedItem);

    if (!initial && widget.onChanged != null) {
      widget.onChanged(item);
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();

    super.dispose();
  }
}

class AppSelectFormField<T> extends StatefulWidget {
  final List<AppSelectFormFieldItem<T>> items;
  final String labelText;
  final String dialogHelpText;
  final String helperText;
  final Icon icon;
  final FormFieldValidator<AppSelectFormFieldItem<T>> validator;
  final FormFieldSetter<AppSelectFormFieldItem<T>> onChanged;
  final FormFieldSetter<AppSelectFormFieldItem<T>> onSaved;
  final bool focusNextOnSelection;
  final T initialValue;

  const AppSelectFormField({
    Key key,
    @required this.items,
    this.labelText,
    this.helperText,
    this.icon,
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.dialogHelpText,
    this.focusNextOnSelection = false,
  }) : super(key: key);

  @override
  _AppSelectFormFieldState<T> createState() => _AppSelectFormFieldState<T>();
}

class _AppSelectFormFieldState<T> extends State<AppSelectFormField<T>> {
  AppSelectFormFieldItem<T> selectedItem;

  @override
  void initState() {
    super.initState();

    selectedItem = _getInitialSelection();
  }

  @override
  Widget build(BuildContext context) {
    return AppSelectionScreenFormField<AppSelectFormFieldItem<T>>(
      onTap: onTap,
      itemToStringConverter: (item) => item.text,
      labelText: widget.labelText,
      helperText: widget.helperText,
      icon: widget.icon,
      prefixIcon: selectedItem?.icon,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      validator: widget.validator,
      initialSelection: selectedItem,
    );
  }

  AppSelectFormFieldItem<T> _getInitialSelection() {
    if (widget.initialValue == null) {
      return null;
    }

    final initialSelection =
        widget.items.firstWhere((e) => e.value == widget.initialValue);
    if (initialSelection == null) {
      throw ArgumentError.value('initialValue',
          'Unable to find initial value in AppSelectFormField items');
    }

    return initialSelection;
  }

  Future<AppSelectFormFieldItem<T>> onTap(BuildContext context) async {
    final item = await showDialog<AppSelectFormFieldItem<T>>(
        context: context,
        builder: (BuildContext context) {
          return AppFormSingleSelectDialog<T>(
            items: widget.items,
            selectedValue: selectedItem?.value,
            title: widget.labelText,
            helpText: widget.dialogHelpText,
          );
        });

    setState(() => selectedItem = item ?? selectedItem);

    if (item != null && widget.focusNextOnSelection) {
      FocusScope.of(context).nextFocus();
    }

    return item;
  }
}

class AppMultipleSelectFormField<T> extends StatefulWidget {
  final List<AppSelectFormFieldItem<T>> items;
  final List<T> initialValues;
  final String labelText;
  final String helperText;
  final Icon icon;
  final FormFieldSetter<List<AppSelectFormFieldItem<T>>> onChanged;
  final FormFieldSetter<List<AppSelectFormFieldItem<T>>> onSaved;
  final bool focusNextOnSelection;

  const AppMultipleSelectFormField({
    Key key,
    @required this.items,
    this.initialValues,
    this.labelText,
    this.helperText,
    this.icon,
    this.onChanged,
    this.onSaved,
    this.focusNextOnSelection = false,
  }) : super(key: key);

  @override
  _AppMultipleSelectFormFieldState<T> createState() =>
      _AppMultipleSelectFormFieldState<T>();
}

class _AppMultipleSelectFormFieldState<T>
    extends State<AppMultipleSelectFormField<T>> {
  List<AppSelectFormFieldItem<T>> _selectedItems;

  @override
  void initState() {
    super.initState();

    _selectedItems = _getInitialSelections();
  }

  List<AppSelectFormFieldItem<T>> _getInitialSelections() {
    if (widget.initialValues == null) {
      return null;
    }

    return widget.items
        .where((e) => widget.initialValues.contains(e.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppSelectionScreenFormField<List<AppSelectFormFieldItem<T>>>(
      onTap: onTap,
      itemToStringConverter: (items) => items.map((e) => e.text).join(', '),
      labelText: widget.labelText,
      helperText: widget.helperText,
      initialSelection: _selectedItems,
      icon: widget.icon,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
    );
  }

  Future<List<AppSelectFormFieldItem<T>>> onTap(BuildContext context) async {
    final items = await showDialog<List<AppSelectFormFieldItem<T>>>(
        context: context,
        builder: (BuildContext context) {
          return AppFormMultipleSelectDialog<T>(
            title: widget.labelText,
            items: widget.items,
            selectedItems: _selectedItems,
          );
        });

    _selectedItems = items ?? _selectedItems;

    if (items != null && widget.focusNextOnSelection) {
      FocusScope.of(context).nextFocus();
    }

    return items;
  }
}

class AppDatePickerFormField extends StatefulWidget {
  final LocalDate initialDate;
  final LocalDate selectedDate;
  final LocalDate firstDate;
  final LocalDate lastDate;

  final String labelText;
  final String helperText;
  final Widget icon;
  final Widget prefixIcon;
  final FormFieldValidator<LocalDate> validator;
  final FormFieldSetter<LocalDate> onDateSaved;
  final FormFieldSetter<LocalDate> onDateChanged;
  final DateFormat dateFormat;
  final DatePickerEntryMode initialEntryMode;
  final DatePickerMode initialDatePickerMode;

  const AppDatePickerFormField({
    Key key,
    @required this.initialDate,
    @required this.firstDate,
    @required this.lastDate,
    this.selectedDate,
    this.onDateSaved,
    this.onDateChanged,
    this.dateFormat,
    this.labelText,
    this.helperText,
    this.icon,
    this.prefixIcon,
    this.validator,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    this.initialDatePickerMode = DatePickerMode.day,
  }) : super(key: key);

  @override
  _AppDatePickerFormFieldState createState() => _AppDatePickerFormFieldState();
}

class _AppDatePickerFormFieldState extends State<AppDatePickerFormField> {
  static final DateFormat _defaultDateFormat = DateFormat.yMd();

  // This is a bug with platform translation. Incorrect format is shown. Set to correct one.
  static const _fieldHintText = 'yyyy-mm-dd';

  LocalDate selectedDateTime;

  @override
  void initState() {
    super.initState();

    selectedDateTime = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return AppSelectionScreenFormField<LocalDate>(
      onTap: _onTap,
      itemToStringConverter: (date) {
        return (widget.dateFormat ?? _defaultDateFormat)
            .format(date.toDateTimeUnspecified())
            .capitalizeFirst();
      },
      labelText: widget.labelText,
      helperText: widget.helperText,
      icon: widget.icon,
      prefixIcon: widget.prefixIcon,
      onSaved: widget.onDateSaved,
      onChanged: widget.onDateChanged,
      initialSelection: selectedDateTime,
      validator: widget.validator,
    );
  }

  Future<LocalDate> _onTap(BuildContext context) async {
    final dateTime = await showDatePicker(
      context: context,
      firstDate: widget.firstDate.toDateTimeUnspecified(),
      lastDate: widget.lastDate.toDateTimeUnspecified(),
      initialDate: widget.initialDate.toDateTimeUnspecified(),
      initialDatePickerMode: widget.initialDatePickerMode,
      initialEntryMode: widget.initialEntryMode,
      fieldHintText: _fieldHintText,
    );

    if (dateTime == null) {
      return null;
    }

    return selectedDateTime = LocalDate.dateTime(dateTime);
  }
}

class AppTimePickerFormField extends StatefulWidget {
  final LocalTime initialTime;
  final String labelText;
  final String helperText;
  final Widget prefixIcon;
  final FormFieldSetter<LocalTime> onTimeSaved;
  final FormFieldSetter<LocalTime> onTimeChanged;

  const AppTimePickerFormField({
    Key key,
    @required this.initialTime,
    this.onTimeSaved,
    this.onTimeChanged,
    this.labelText,
    this.helperText,
    this.prefixIcon,
  }) : super(key: key);

  @override
  _AppTimePickerFormFieldState createState() => _AppTimePickerFormFieldState();
}

class _AppTimePickerFormFieldState extends State<AppTimePickerFormField> {
  LocalTime _selectedTimeOfDay;

  @override
  Widget build(BuildContext context) {
    _selectedTimeOfDay = widget.initialTime;

    return AppSelectionScreenFormField<LocalTime>(
      onTap: _onTap,
      itemToStringConverter: (newlySelectedTimeOfDay) {
        return newlySelectedTimeOfDay.formatHoursAndMinutes();
      },
      labelText: widget.labelText,
      helperText: widget.helperText,
      prefixIcon: widget.prefixIcon,
      onSaved: widget.onTimeSaved,
      onChanged: _onTimeChanged,
      initialSelection: widget.initialTime,
    );
  }

  void _onTimeChanged(v) {
    if (_selectedTimeOfDay != null) {
      widget.onTimeChanged(_selectedTimeOfDay);
    }
  }

  Future<LocalTime> _onTap(BuildContext _) async {
    final localTime = _selectedTimeOfDay ?? LocalTime.currentClockTime();

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: localTime.hourOfDay, minute: localTime.minuteOfHour),
    );

    if (timeOfDay == null) {
      return null;
    }

    return _selectedTimeOfDay = LocalTime(timeOfDay.hour, timeOfDay.minute, 0);
  }
}

class AppIntegerFormField extends StatelessWidget {
  final String labelText;
  final String helperText;
  final String hintText;
  final int initialValue;
  final Widget icon;
  final FormFieldValidator<int> validator;
  final FormFieldSetter<int> onSaved;
  final FormFieldSetter<int> onChanged;
  final String suffixText;
  final bool autoFocus;
  final FocusNode focusNode;
  final TextInputAction textInputAction;

  const AppIntegerFormField({
    Key key,
    @required this.labelText,
    this.onSaved,
    this.helperText,
    this.initialValue,
    this.icon,
    this.validator,
    this.suffixText,
    this.hintText,
    this.onChanged,
    this.focusNode,
    this.autoFocus = false,
    this.textInputAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      labelText: labelText,
      helperText: helperText,
      hintText: hintText,
      icon: icon,
      validator: _validator,
      autoFocus: autoFocus,
      initialValue: initialValue?.toString(),
      onSaved: onSaved != null ? _onSaved : null,
      onChanged: onChanged != null ? _onChanged : null,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      suffixText: suffixText,
      focusNode: focusNode,
      textInputAction: textInputAction,
    );
  }

  String _validator(String text) {
    if (validator == null) {
      return null;
    }

    return validator(int.tryParse(text));
  }

  int _parseToInt(String v) {
    return (v != null && v.isNotEmpty) ? int.parse(v) : null;
  }

  void _onSaved(String v) {
    final n = _parseToInt(v);

    onSaved(n);
  }

  void _onChanged(String v) {
    final n = _parseToInt(v);

    onChanged(n);
  }
}

class AppDoubleInputField extends StatelessWidget {
  static final floatRegexPattern =
      RegExp(r'^((0|([1-9][0-9]{0,3}))(\.|,)?\d*)$');

  final String labelText;
  final String helperText;
  final String hintText;
  final double initialValue;
  final Widget icon;
  final FormFieldValidator<double> validator;
  final FormFieldSetter<double> onSaved;
  final FormFieldSetter<double> onChanged;
  final String suffixText;
  final int fractionDigits;
  final TextInputAction textInputAction;

  const AppDoubleInputField({
    Key key,
    @required this.labelText,
    @required this.fractionDigits,
    this.onSaved,
    this.onChanged,
    this.hintText,
    this.helperText,
    this.initialValue,
    this.icon,
    this.validator,
    this.suffixText,
    this.textInputAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      labelText: labelText,
      helperText: helperText,
      icon: icon,
      initialValue: initialValue?.toStringAsFixed(fractionDigits),
      validator: _validator,
      hintText: hintText,
      onChanged: onChanged != null ? _onChanged : null,
      onSaved: onSaved != null ? _onSaved : null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(floatRegexPattern)],
      suffixText: suffixText,
      textInputAction: textInputAction,
    );
  }

  String _validator(String text) {
    if (validator == null) {
      return null;
    }

    return validator(double.tryParse(text.replaceFirst(',', '.')));
  }

  double _parseDouble(String v) {
    if (v == null || v.isEmpty) {
      return null;
    }
    return double.parse(
        double.parse(v.replaceFirst(',', '.')).toStringAsFixed(fractionDigits));
  }

  void _onSaved(String v) {
    final n = _parseDouble(v);

    onSaved(n);
  }

  void _onChanged(String v) {
    final n = _parseDouble(v);

    onChanged(n);
  }
}
