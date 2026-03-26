import 'package:flutter/material.dart';

class FlutterFlowIconButton extends StatelessWidget {
  const FlutterFlowIconButton({
    super.key,
    this.borderColor = Colors.transparent,
    this.borderRadius = 8,
    this.borderWidth = 0,
    this.buttonSize = 40,
    required this.icon,
    this.onPressed,
  });

  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final double buttonSize;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
