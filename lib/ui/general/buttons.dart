import 'package:flutter/material.dart';

class AppElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget label;

  final Color? color;
  final Color? textColor;
  final EdgeInsets innerPadding;

  const AppElevatedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.color,
    this.textColor,
    this.innerPadding = const EdgeInsets.all(16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: color ?? Theme.of(context).primaryColor,
        padding: innerPadding,
      ),
      onPressed: onPressed,
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 16,
          color: textColor ?? Colors.white,
        ),
        child: label,
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget label;
  final Widget icon;
  final Color? textColor;

  final Color? color;
  final EdgeInsets innerPadding;

  const LoginButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.textColor,
    this.innerPadding = const EdgeInsets.all(16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        primary: color ?? Theme.of(context).primaryColor,
        padding: innerPadding,
      ),
      onPressed: onPressed,
      icon: icon,
      label: DefaultTextStyle(
        style: TextStyle(
          color: textColor ?? Colors.white,
        ),
        child: label,
      ),
    );
  }
}

class SectionFooterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const SectionFooterButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
