// dialog_util.dart

import 'package:flutter/material.dart';

class DialogUtil {
  static void messageDialog({
    required BuildContext context,
    required void Function() onAccept,
    required void Function() onCancel,
    required String title,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: SizedBox(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed: onCancel,
                        child: Text(
                          'CANCELAR',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: onAccept,
                        child: Text(
                          "ACEPTAR",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
