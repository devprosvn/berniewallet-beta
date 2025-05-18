// config/theme.dart - App theming

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: Colors.grey[50], // Light background
      fontFamily: GoogleFonts.roboto().fontFamily,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.lato(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lato(
            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        displayMedium: GoogleFonts.lato(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
        displaySmall: GoogleFonts.lato(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineMedium: GoogleFonts.lato(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        headlineSmall: GoogleFonts.lato(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        titleLarge: GoogleFonts.lato(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        bodyLarge: GoogleFonts.roboto(fontSize: 16, color: Colors.black54),
        bodyMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
        labelLarge: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white), // For buttons
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius),
        ),
        buttonColor: kPrimaryColor,
        textTheme: ButtonTextTheme.primary,
        height: kButtonHeight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          padding: const EdgeInsets.symmetric(
              vertical: kMediumPadding, horizontal: kDefaultPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius),
          ),
          textStyle: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kPrimaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
              vertical: kMediumPadding, horizontal: kDefaultPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius),
          ),
          textStyle: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.w500, color: kPrimaryColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
            vertical: kMediumPadding, horizontal: kDefaultPadding),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius),
          borderSide: const BorderSide(color: kErrorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius),
          borderSide: const BorderSide(color: kErrorColor, width: 2),
        ),
        labelStyle: GoogleFonts.roboto(color: Colors.grey[700]),
        hintStyle: GoogleFonts.roboto(color: Colors.grey[500]),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        margin:
            const EdgeInsets.symmetric(vertical: kSmallPadding, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kPrimaryColor.withAlpha((0.1 * 255).round()),
        disabledColor: Colors.grey[300]!,
        selectedColor: kPrimaryColor,
        secondarySelectedColor: kPrimaryColor,
        padding: const EdgeInsets.all(kSmallPadding),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius)),
        labelStyle: GoogleFonts.roboto(
            color: kPrimaryColor, fontWeight: FontWeight.w500),
        secondaryLabelStyle: GoogleFonts.roboto(
            color: Colors.white, fontWeight: FontWeight.w500),
        brightness: Brightness.light,
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: kPrimaryColor,
        secondary: kSecondaryColor,
        error: kErrorColor,
        brightness: Brightness.light,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // If you want a dark theme, you can define it here as well.
  // static ThemeData get darkTheme { ... }
}
