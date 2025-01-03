import 'package:agendaapp/_comum/minhascores.dart';
import 'package:flutter/material.dart';

InputDecoration getAuthenticationinputDecoration(String label, {Icon? icons}) {
  return InputDecoration(
    icon: icons,
    hintText: label,
    fillColor: Minhascores.brancosuave,
    filled: true,
    contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(34),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(34),
      borderSide:
          const BorderSide(color: Color.fromARGB(255, 236, 165, 203), width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(34),
      borderSide: const BorderSide(color: Color(0xFFE1A4C5), width: 4),
    ),
    errorStyle: const TextStyle(
      color: Color.fromARGB(255, 0, 0, 0),
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
  );
}
