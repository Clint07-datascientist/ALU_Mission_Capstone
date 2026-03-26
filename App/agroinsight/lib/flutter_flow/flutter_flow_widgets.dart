import 'package:flutter/material.dart';

class FFButtonOptions {
  const FFButtonOptions({
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.iconPadding = EdgeInsets.zero,
    this.color,
    this.iconColor,
    this.textStyle,
    this.elevation = 0,
    this.borderSide = BorderSide.none,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry iconPadding;
  final Color? color;
  final Color? iconColor;
  final TextStyle? textStyle;
  final double elevation;
  final BorderSide borderSide;
  final BorderRadius borderRadius;
}

class FFButtonWidget extends StatelessWidget {
  const FFButtonWidget({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    required this.options,
  });

  final VoidCallback? onPressed;
  final String text;
  final Widget? icon;
  final FFButtonOptions options;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: options.color ?? Theme.of(context).colorScheme.primary,
      foregroundColor:
          options.textStyle?.color ?? Theme.of(context).colorScheme.onPrimary,
      padding: options.padding,
      elevation: options.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: options.borderRadius,
        side: options.borderSide,
      ),
      textStyle: options.textStyle,
    );

    final label = Text(text, style: options.textStyle);
    final buttonChild = icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: options.iconColor),
                child: icon!,
              ),
              Padding(padding: options.iconPadding, child: label),
            ],
          );

    return SizedBox(
      width: options.width,
      height: options.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: buttonChild,
      ),
    );
  }
}
