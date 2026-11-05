import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fundoConteudo,
      child: const Center(
        child: Text('Histórico de consultas'),
      ),
    );
  }
}