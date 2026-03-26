import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ValidatorFunction = String? Function(BuildContext, String?);

abstract class FlutterFlowModel<T extends StatefulWidget> {
  void dispose() {}
}

M createModel<M>(BuildContext context, M Function() modelFactory) {
  return modelFactory();
}

extension ValidatorFunctionExtension on ValidatorFunction? {
  FormFieldValidator<String> asValidator(BuildContext context) {
    return (value) => this?.call(context, value);
  }
}

extension StringCapitalization on String {
  String toCapitalization(TextCapitalization capitalization) {
    switch (capitalization) {
      case TextCapitalization.characters:
        return toUpperCase();
      case TextCapitalization.words:
        return split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
            )
            .join(' ');
      case TextCapitalization.sentences:
        if (isEmpty) return this;
        return '${this[0].toUpperCase()}${substring(1)}';
      case TextCapitalization.none:
        return this;
    }
  }
}

extension WidgetListExtensions on List<Widget> {
  List<Widget> divide(Widget separator) {
    if (isEmpty) return this;
    final widgets = <Widget>[first];
    for (var i = 1; i < length; i++) {
      widgets.add(separator);
      widgets.add(this[i]);
    }
    return widgets;
  }

  List<Widget> addToStart(Widget widget) => [widget, ...this];

  List<Widget> addToEnd(Widget widget) => [...this, widget];
}

bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
bool get isiOS => defaultTargetPlatform == TargetPlatform.iOS;
