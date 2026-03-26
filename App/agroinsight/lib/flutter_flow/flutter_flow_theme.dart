import 'package:flutter/material.dart';

class FlutterFlowTheme {
  static _FlutterFlowThemeData of(BuildContext context) {
    return _FlutterFlowThemeData(context);
  }
}

class _FlutterFlowThemeData {
  _FlutterFlowThemeData(this.context);

  final BuildContext context;

  ThemeData get _theme => Theme.of(context);
  TextTheme get _textTheme => _theme.textTheme;

  Color get primaryBackground => _theme.scaffoldBackgroundColor;
  Color get primaryText => _theme.colorScheme.onSurface;
  Color get secondaryText => _theme.colorScheme.onSurfaceVariant;

  TextStyle get titleLarge =>
      _textTheme.titleLarge ?? const TextStyle(fontSize: 22);
  TextStyle get titleMedium =>
      _textTheme.titleMedium ?? const TextStyle(fontSize: 16);
  TextStyle get titleSmall =>
      _textTheme.titleSmall ?? const TextStyle(fontSize: 14);
  TextStyle get headlineSmall =>
      _textTheme.headlineSmall ?? const TextStyle(fontSize: 24);
  TextStyle get headlineMedium =>
      _textTheme.headlineMedium ?? const TextStyle(fontSize: 28);
  TextStyle get bodyLarge => _textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
  TextStyle get bodyMedium =>
      _textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
  TextStyle get bodySmall => _textTheme.bodySmall ?? const TextStyle(fontSize: 12);
  TextStyle get labelLarge =>
      _textTheme.labelLarge ?? const TextStyle(fontSize: 14);
  TextStyle get labelMedium =>
      _textTheme.labelMedium ?? const TextStyle(fontSize: 12);
  TextStyle get labelSmall =>
      _textTheme.labelSmall ?? const TextStyle(fontSize: 11);
}

extension FlutterFlowTextStyleHelpers on TextStyle {
  TextStyle override({
    TextStyle? font,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? lineHeight,
  }) {
    return copyWith(
      fontFamily: font?.fontFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );
  }
}
