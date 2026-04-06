import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  
  static final TextStyle logo = GoogleFonts.plusJakartaSans(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 72 / 44,
    letterSpacing: -3.6,
  );

  static final TextStyle h1 = GoogleFonts.plusJakartaSans(
    fontSize: 33,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle h2 = GoogleFonts.plusJakartaSans(
    fontSize: 25,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle h3 = GoogleFonts.plusJakartaSans(
    fontSize: 19,
    fontWeight: FontWeight.w600, 
  );


  static final TextStyle bodyBold = GoogleFonts.sora(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle body = GoogleFonts.sora(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static final TextStyle captionBold = GoogleFonts.sora(
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle caption = GoogleFonts.sora(
    fontSize: 11,
    fontWeight: FontWeight.normal,
  );

  static final TextStyle captionSmall = GoogleFonts.sora(
    fontSize: 8,
    fontWeight: FontWeight.normal,
  );
}
