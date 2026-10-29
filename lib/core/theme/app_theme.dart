import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tema global do app. Botões, campos de texto, AppBar etc.
/// já ficam no padrão automaticamente.
class AppTheme {
  AppTheme._();

  static ThemeData get tema {
    // Manual da marca: Montserrat para textos, Cinzel para títulos
    final textoBase = GoogleFonts.montserratTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.fundoConteudo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.verde,
        primary: AppColors.verde,
        secondary: AppColors.roxo,
        surface: AppColors.branco,
        onSurface: AppColors.textoPrincipal,
        error: AppColors.erro,
      ),
      textTheme: textoBase.copyWith(
        displayLarge: _titulo(textoBase.displayLarge),
        displayMedium: _titulo(textoBase.displayMedium),
        displaySmall: _titulo(textoBase.displaySmall),
        headlineLarge: _titulo(textoBase.headlineLarge),
        headlineMedium: _titulo(textoBase.headlineMedium),
        headlineSmall: _titulo(textoBase.headlineSmall),
        titleLarge: _subtitulo(textoBase.titleLarge),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.verdeFundo,
        foregroundColor: AppColors.textoPrincipal,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.verdeFundo,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.branco,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: AppColors.branco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borda,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Títulos: Cinzel em negrito
  static TextStyle _titulo(TextStyle? base) =>
      GoogleFonts.cinzel(textStyle: base, fontWeight: FontWeight.bold);

  /// Subtítulos: Cinzel sem negrito
  static TextStyle _subtitulo(TextStyle? base) =>
      GoogleFonts.cinzel(textStyle: base);
}
