import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema global do app. Botões, campos de texto, AppBar etc.
/// já ficam no padrão automaticamente.
class AppTheme {
  AppTheme._();

  static ThemeData get tema => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.fundoConteudo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.verde,
      primary: AppColors.verde,
      surface: AppColors.branco,
      onSurface: AppColors.textoPrincipal,
      error: AppColors.erro,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.verdeFundo,
      foregroundColor: AppColors.marromEscuro,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: AppColors.verdeFundo),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.branco,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.verde,
        foregroundColor: AppColors.branco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borda,
      thickness: 1,
      space: 1,
    ),
  );
}
