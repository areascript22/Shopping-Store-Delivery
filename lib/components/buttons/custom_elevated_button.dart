import 'package:flutter/material.dart';

class CustomElevatedButton extends StatefulWidget {
  final void Function()? onTap;
  final Widget text;
  final Color backgroundColor;
  final double? borderRadius;
  final TextStyle? textStyle;
  const CustomElevatedButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.backgroundColor,
    required this.textStyle,
    this.borderRadius,
  });

  @override
  State<CustomElevatedButton> createState() => _CustomElevatedButtonState();
}

class _CustomElevatedButtonState extends State<CustomElevatedButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 10.0)),
        minimumSize: const Size(100, 50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.text,
        ],
      ),
    );
  }
}
