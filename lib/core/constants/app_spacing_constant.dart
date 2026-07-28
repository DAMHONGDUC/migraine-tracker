import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Single home for every screenutil dimension used in the app — no raw
/// `16.w` / `12.h` / `20.r` literals in widgets. Getters (not consts)
/// because screenutil resolves at runtime, after ScreenUtilInit.
///
/// Naming: unit prefix + design-size value. `w` = horizontal, `h` =
/// vertical, `r` = square/circular (radius, icons, fixed boxes),
/// `sp` = font size.
abstract final class AppSpacingConstant {
  // --- Horizontal (.w) ---
  static double get w2 => 2.w;
  static double get w4 => 4.w;
  static double get w6 => 6.w;
  static double get w8 => 8.w;
  static double get w12 => 12.w;
  static double get w14 => 14.w;
  static double get w16 => 16.w;
  static double get w20 => 20.w;
  static double get w24 => 24.w;
  static double get w28 => 28.w;
  static double get w32 => 32.w;
  static double get w40 => 40.w;
  static double get w44 => 44.w;
  static double get w46 => 46.w;
  static double get w48 => 48.w;
  static double get w54 => 54.w;
  static double get w56 => 56.w;
  static double get w160 => 160.w;

  // --- Vertical (.h) ---
  static double get h2 => 2.h;
  static double get h4 => 4.h;
  static double get h6 => 6.h;
  static double get h8 => 8.h;
  static double get h12 => 12.h;
  static double get h16 => 16.h;
  static double get h20 => 20.h;
  static double get h22 => 22.h;
  static double get h24 => 24.h;
  static double get h32 => 32.h;
  static double get h34 => 34.h;
  static double get h38 => 38.h;
  static double get h40 => 40.h;
  static double get h42 => 42.h;
  static double get h44 => 44.h;
  static double get h64 => 64.h;
  static double get h56 => 56.h;
  static double get h62 => 62.h;
  static double get h68 => 68.h;
  static double get h96 => 96.h;
  static double get h108 => 108.h;
  static double get h160 => 160.h;
  static double get h200 => 200.h;

  // --- Square / radius (.r) ---
  static double get r3 => 3.r;
  static double get r4 => 4.r;
  static double get r6 => 6.r;
  static double get r12 => 12.r;
  static double get r16 => 16.r;
  static double get r18 => 18.r;
  static double get r20 => 20.r;
  static double get r22 => 22.r;
  static double get r24 => 24.r;
  static double get r26 => 26.r;
  static double get r28 => 28.r;
  static double get r44 => 44.r;
  static double get r64 => 64.r;
  static double get r88 => 88.r;
  static double get r999 => 999.r;

  /// Head-location diagram diameter (log flow step 2).
  static double get r240 => 240.r;

  // --- Font (.sp) ---
  static double get sp8 => 8.sp;
  static double get sp10 => 10.sp;
  static double get sp11 => 11.sp;
  static double get sp12 => 12.sp;
  static double get sp14 => 14.sp;
  static double get sp16 => 16.sp;
  static double get sp22 => 22.sp;
  static double get sp24 => 24.sp;
  static double get sp28 => 28.sp;
  static double get sp36 => 36.sp;
}
