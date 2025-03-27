import 'package:flutter/material.dart';

class AppTheme {
  // Основная текстовая тема с шрифтом Jura
  static const TextTheme juraTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.bold,
      fontSize: 32,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.w600,
      fontSize: 28,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.w500,
      fontSize: 24,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.w500,
      fontSize: 18,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.normal,
      fontSize: 14,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.w300,
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Jura',
      fontWeight: FontWeight.w400,
      fontSize: 10,
    ),
  );

  // Вспомогательная текстовая тема с шрифтом Nunito
  static const TextTheme nunitoTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.bold,
      fontSize: 32,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w600,
      fontSize: 28,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      fontSize: 24,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      fontSize: 18,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.normal,
      fontSize: 14,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w300,
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w400,
      fontSize: 10,
    ),
  );

  // Метод для создания светлой темы
  static ThemeData lightTheme(ColorScheme colorScheme) {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: juraTextTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: colorScheme.surface,
      useMaterial3: true,
    );
  }

  // Метод для создания темной темы
  static ThemeData darkTheme(ColorScheme colorScheme) {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: juraTextTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: colorScheme.surface,
      useMaterial3: true,
    );
  }

  // Предустановленные схемы цветов для светлой и темной тем
  static ColorScheme lightColorScheme = const ColorScheme.light(
    primary: Color(4280182150),
    surfaceTint: Color(4280182150),
    onPrimary: Color(4294967295),
    primaryContainer: Color(4291160063),
    onPrimaryContainer: Color(4278197805),
    secondary: Color(4283326829),
    onSecondary: Color(4294967295),
    secondaryContainer: Color(4291945972),
    onSecondaryContainer: Color(4278853160),
    tertiary: Color(4284570236),
    onTertiary: Color(4294967295),
    tertiaryContainer: Color(4293385983),
    onTertiaryContainer: Color(4280096565),
    error: Color(4290386458),
    onError: Color(4294967295),
    errorContainer: Color(4294957782),
    onErrorContainer: Color(4282449922),
    surface: Color(4294376190),
    onSurface: Color(4279770143),
    onSurfaceVariant: Color(4282468429),
    outline: Color(4285626494),
    outlineVariant: Color(4290889677),
    shadow: Color(4278190080),
    scrim: Color(4278190080),
    inverseSurface: Color(4281086260),
    inversePrimary: Color(4287680244),
    primaryFixed: Color(4291160063),
    onPrimaryFixed: Color(4278197805),
    primaryFixedDim: Color(4287680244),
    onPrimaryFixedVariant: Color(4278209642),
    secondaryFixed: Color(4291945972),
    onSecondaryFixed: Color(4278853160),
    secondaryFixedDim: Color(4290169304),
    onSecondaryFixedVariant: Color(4281813333),
    tertiaryFixed: Color(4293385983),
    onTertiaryFixed: Color(4280096565),
    tertiaryFixedDim: Color(4291543529),
    onTertiaryFixedVariant: Color(4282991203),
    surfaceDim: Color(4292336351),
    surfaceBright: Color(4294376190),
    surfaceContainerLowest: Color(4294967295),
    surfaceContainerLow: Color(4293981432),
    surfaceContainer: Color(4293652211),
    surfaceContainerHigh: Color(4293257453),
    surfaceContainerHighest: Color(4292862951),
  );

  static ColorScheme darkColorScheme = const ColorScheme.dark(
    primary: Color(4287680244),
    surfaceTint: Color(4287680244),
    onPrimary: Color(4278203466),
    primaryContainer: Color(4278209642),
    onPrimaryContainer: Color(4291160063),
    secondary: Color(4290169304),
    onSecondary: Color(4280300350),
    secondaryContainer: Color(4281813333),
    onSecondaryContainer: Color(4291945972),
    tertiary: Color(4291543529),
    onTertiary: Color(4281478220),
    tertiaryContainer: Color(4282991203),
    onTertiaryContainer: Color(4293385983),
    error: Color(4294948011),
    onError: Color(4285071365),
    errorContainer: Color(4287823882),
    onErrorContainer: Color(4294957782),
    surface: Color(4279178263),
    onSurface: Color(4292862951),
    onSurfaceVariant: Color(4290889677),
    outline: Color(4287337111),
    outlineVariant: Color(4282468429),
    shadow: Color(4278190080),
    scrim: Color(4278190080),
    inverseSurface: Color(4292862951),
    inversePrimary: Color(4280182150),
    primaryFixed: Color(4291160063),
    onPrimaryFixed: Color(4278197805),
    primaryFixedDim: Color(4287680244),
    onPrimaryFixedVariant: Color(4278209642),
    secondaryFixed: Color(4291945972),
    onSecondaryFixed: Color(4278853160),
    secondaryFixedDim: Color(4290169304),
    onSecondaryFixedVariant: Color(4281813333),
    tertiaryFixed: Color(4293385983),
    onTertiaryFixed: Color(4280096565),
    tertiaryFixedDim: Color(4291543529),
    onTertiaryFixedVariant: Color(4282991203),
    surfaceDim: Color(4279178263),
    surfaceBright: Color(4281678397),
    surfaceContainerLowest: Color(4278849298),
    surfaceContainerLow: Color(4279770143),
    surfaceContainer: Color(4280033315),
    surfaceContainerHigh: Color(4280691502),
    surfaceContainerHighest: Color(4281414969),
  );
}
