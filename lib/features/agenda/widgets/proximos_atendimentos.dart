import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../agenda_service.dart';
import '../datas.dart';

/// Os próximos 3 atendimentos da semana carregada.
class ProximosAtendimentos extends StatelessWidget {
  final AgendaDados? dados;

  const ProximosAtendimentos({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    // A lista já vem ordenada por horário da API
    final proximos = (dados?.atendimentos ?? [])
        .where((a) => a.inicio.isAfter(agora))
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_note_outlined, size: 20),
              SizedBox(width: 8),
              Text(
                'Próximos atendimentos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (proximos.isEmpty)
            const Text(
              'Nenhum próximo atendimento nesta semana',
              style: TextStyle(color: AppColors.textoSecundario),
            )
          else
            for (final atendimento in proximos) _linha(atendimento),
        ],
      ),
    );
  }

  Widget _linha(Atendimento atendimento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borda),
      ),
      child: Row(
        children: [
          // Quadradinho com o dia
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.verdeFundo,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  diasDaSemanaCurtos[atendimento.inicio.weekday - 1],
                  style: const TextStyle(fontSize: 10),
                ),
                Text(
                  '${atendimento.inicio.day}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atendimento.cliente,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${atendimento.servico} · ${hora(atendimento.inicio)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
