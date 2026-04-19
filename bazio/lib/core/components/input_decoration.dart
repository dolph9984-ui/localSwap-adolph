import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:flutter/material.dart';

class AppInputDecoration {
  //on factorise la creation des bordures pour pas se repeter
  static OutlineInputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  //le style de base de tous nos champs de texte
  static InputDecoration defaultStyle({
    required String hint,
    String? label,
    Widget? suffixIcon,
    String? errorText,
    bool isEmpty = true,
    bool isValid = false,
  }) {
    //on change la couleur selon si c'est vide, valide ou en erreur
    final Color labelColor = isEmpty
        ? AppColors.primary
        : isValid
            ? Colors.green
            : Colors.red;

    final Color borderColor = isEmpty
        ? const Color(0xFFD9D9D9)
        : isValid
            ? Colors.green
            : Colors.red;

    return InputDecoration(
      hintText: hint,
      labelText: label,
      errorText: errorText,
      hintStyle: AppTextStyles.body.copyWith(color: Colors.grey),
      labelStyle: AppTextStyles.body.copyWith(color: Colors.grey),
      floatingLabelStyle: AppTextStyles.body.copyWith(color: labelColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 50,
        minHeight: 24,
      ),
      border: _border(borderColor),
      enabledBorder: _border(borderColor),
      focusedBorder: _border(isEmpty ? AppColors.primary : borderColor, width: 1.5),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red, width: 1.5),
    );
  }
}