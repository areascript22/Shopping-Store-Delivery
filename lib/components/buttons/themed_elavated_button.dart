import 'package:flutter/material.dart';

class ThemedElevatedButton extends StatefulWidget {
  final void Function()? onTap;
  final Widget child;

  const ThemedElevatedButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  State<ThemedElevatedButton> createState() => _ThemedElevatedButtonState();
}

class _ThemedElevatedButtonState extends State<ThemedElevatedButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.onTap,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.child,
        ],
      ),
    );
  }
}
