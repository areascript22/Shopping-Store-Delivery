import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;

  LoadingOverlay({
    this.message = "Procesando transacción",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withAlpha(150), // Semi-transparent black color
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(), // Loading spinner
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                  fontFamily: AnsiColor.ansiDefault,
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none),
            ),
          ],
        ),
      ),
    );
  }
}
