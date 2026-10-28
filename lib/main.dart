import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

void main() {
  runApp(const RokuzenApp());
}

class RokuzenApp extends StatelessWidget {
  const RokuzenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rokuzen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      home: const HomePage(),
    );
  }
}
