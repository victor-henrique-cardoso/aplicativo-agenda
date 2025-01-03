import 'package:flutter/material.dart';

mostrarsnackbar(
    {required BuildContext context,
    required String texto,
    bool iserro = true}) {
  SnackBar snackBar = SnackBar(
    content: Text(texto),
    backgroundColor: (iserro) ? Colors.red : Colors.green,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
