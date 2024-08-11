import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'coloors.dart';
import 'extension/extension_theme.dart';

ThemeData darkTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: Coolors.backgroundDark,
    extensions: [
      CustomThemeExtension.darkMode,
    ],
    appBarTheme: const AppBarTheme(
      backgroundColor: Coolors.greyBackground,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Coolors.greyDark,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(
        color: Coolors.greyDark,
      ),
    ),
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: Coolors.purpleDark,
          width: 2.0,
        ),
      ),
      unselectedLabelColor: Coolors.greyDark,
      labelColor: Coolors.greyDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Coolors.purpleDark,
        foregroundColor: Coolors.backgroundDark,
        splashFactory: NoSplash.splashFactory,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Coolors.greyBackground,
      modalBackgroundColor: Coolors.greyBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
    ),
    dialogBackgroundColor: Coolors.greyBackground,
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Coolors.blueDark,
      foregroundColor: Colors.white,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Coolors.greyDark,
      tileColor: Coolors.backgroundDark,
    ),
    switchTheme: const SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(Coolors.greyDark),
      trackColor: WidgetStatePropertyAll(Color(0xFF344047)),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Coolors.purpleDark,
      onPrimary: Coolors.backgroundDark,
      secondary: Coolors.blueDark,
      onSecondary: Colors.white,
      surface: Coolors.greyBackground,
      onSurface: Coolors.greyDark,
      error: Colors.red,
      onError: Colors.white,
    ),
  );
}
