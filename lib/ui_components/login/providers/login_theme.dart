import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginButtonTheme {
  const LoginButtonTheme({
    this.backgroundColor,
    this.highlightColor,
    this.splashColor,
    this.elevation,
    this.highlightElevation,
    this.shape,
  });

  final Color? backgroundColor;
  final Color? highlightColor;
  final Color? splashColor;
  final double? elevation;
  final double? highlightElevation;
  final ShapeBorder? shape;
}

class LoginTheme {
  const LoginTheme({
    this.pageColorLight,
    this.pageColorDark,
    this.primaryColor,
    this.accentColor,
    this.errorColor,
    this.cardTheme = const CardTheme(),
    this.inputTheme = const InputDecorationTheme(filled: true),
    this.buttonTheme = const LoginButtonTheme(),
    this.titleStyle,
    this.bodyStyle,
    this.textFieldStyle,
    this.buttonStyle,
    this.beforeHeroFontSize = 48.0,
    this.afterHeroFontSize = 15.0,
    this.footerBackgroundColor,
    this.switchAuthTextColor,
    this.footerTextStyle,
    this.authButtonPadding,
    this.providerButtonPadding,
    this.footerBottomPadding = 5,
    this.logoWidth,
    this.primaryColorAsInputLabel = false,
    this.headerMargin,
    this.cardInitialHeight,
    this.cardTopPosition,
  });

  final Color? pageColorLight;
  final Color? pageColorDark;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? errorColor;
  final CardTheme cardTheme;
  final InputDecorationTheme inputTheme;
  final LoginButtonTheme buttonTheme;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;
  final TextStyle? textFieldStyle;
  final TextStyle? buttonStyle;
  final double beforeHeroFontSize;
  final double afterHeroFontSize;
  final Color? footerBackgroundColor;
  final Color? switchAuthTextColor;
  final TextStyle? footerTextStyle;
  final EdgeInsets? authButtonPadding;
  final EdgeInsets? providerButtonPadding;
  final double footerBottomPadding;
  final double? logoWidth;
  final bool primaryColorAsInputLabel;
  final double? headerMargin;
  final double? cardInitialHeight;
  final double? cardTopPosition;
}

final loginThemeProvider = Provider<LoginTheme>((ref) {
  return const LoginTheme();
});
