import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../agenda_service.dart';
import '../datas.dart';

/// Os 7 dias da semana, com a quantidade de atendimentos de cada um.
class FaixaSemana extends StatelessWidget {
  final DateTime inicioSemana;
  final DateTime diaSelecionado;
  final AgendaDados dados;
  final ValueChanged<DateTime> aoSelecionar;

  const FaixaSemana({
    super.key,
    required this.inicioSemana,
    required this.diaSelecionado,
    required this.dados,
    required this.aoSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Em telas estreitas, esconde o texto "3 atend." para caber
        final compacto = constraints.maxWidth < 500;
        return Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) SizedBox(width: compacto ? 4 : 8),
              Expanded(
                child: _cartaoDia(inicioSemana.add(Duration(days: i)), compacto),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _cartaoDia(DateTime dia, bool compacto) {
    final quantidade =
        dados.atendimentos.where((a) => mesmoDia(a.inicio, dia)).length;
    final selecionado = mesmoDia(dia, diaSelecionado);
    final ehHoje = mesmoDia(dia, DateTime.now());

    return Material(
      color: selecionado ? AppColors.verdeFundo : AppColors.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selecionado ? AppColors.verde : AppColors.borda,
          width: selecionado ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => aoSelecionar(dia),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                diasDaSemanaCurtos[dia.weekday - 1],
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textoSecundario,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${dia.day}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ehHoje ? AppColors.verdeEscuro : AppColors.textoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              // Bolinha verde quando há atendimentos
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: quantidade > 0
                      ? AppColors.verde
                      : AppColors.cinzaMuitoClaro,
                ),
              ),
              if (!compacto) ...[
                const SizedBox(height: 6),
                Text(
                  quantidade == 0 ? 'Sem atend.' : '$quantidade atend.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
