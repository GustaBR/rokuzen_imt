import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fundoConteudo,
      width: double.infinity,
      child: const Center(
        child: Text('Agenda incompleta'),
      ),
    );
  }
}
