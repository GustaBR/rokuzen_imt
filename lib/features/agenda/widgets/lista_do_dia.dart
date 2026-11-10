import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../agenda_service.dart';
import '../datas.dart';

/// Lista dos atendimentos de um dia, com horário e linha do tempo.
class ListaDoDia extends StatelessWidget {
  final DateTime dia;
  final AgendaDados dados;

  const ListaDoDia({super.key, required this.dia, required this.dados});

  @override
  Widget build(BuildContext context) {
    final atendimentos =
        dados.atendimentos.where((a) => mesmoDia(a.inicio, dia)).toList();
    final turnos = dados.turnos.where((t) => mesmoDia(t.inicio, dia)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                diaPorExtenso(dia),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            _Etiqueta(
              '${atendimentos.length} '
              '${atendimentos.length == 1 ? 'atendimento' : 'atendimentos'}',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          turnos.isEmpty
              ? 'Sem escala neste dia'
              : turnos.map(_textoTurno).join('  ·  '),
          style: const TextStyle(fontSize: 13, color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 16),
        if (atendimentos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhum atendimento neste dia',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ),
          )
        else
          for (var i = 0; i < atendimentos.length; i++)
            _ItemAtendimento(
              atendimento: atendimentos[i],
              ultimo: i == atendimentos.length - 1,
            ),
      ],
    );
  }

  String _textoTurno(Turno turno) {
    final fim = turno.fim == null ? '?' : hora(turno.fim!);
    return 'Turno: ${hora(turno.inicio)} – $fim';
  }
}

class _ItemAtendimento extends StatelessWidget {
  final Atendimento atendimento;
  final bool ultimo;

  const _ItemAtendimento({required this.atendimento, required this.ultimo});

  @override
  Widget build(BuildContext context) {
    final duracao = atendimento.fim?.difference(atendimento.inicio).inMinutes;

    // IntrinsicHeight faz a linha do tempo ter a mesma altura do cartão
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horário
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                hora(atendimento.inicio),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Bolinha e linha da linha do tempo
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.verde,
                  ),
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(width: 1.5, color: AppColors.borda),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Cartão do atendimento
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borda),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.verdeFundo,
                    child: Text(
                      _iniciais(atendimento.cliente),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.verdeMuitoEscuro,
                      ),
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
                          atendimento.servico,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (duracao != null) ...[
                    const SizedBox(width: 8),
                    _Etiqueta('$duracao min'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ex.: "Keila Roberta Toqueira" → "KT"
  String _iniciais(String nome) {
    final partes =
        nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    final primeira = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }
}

/// Etiqueta arredondada, como "4 atendimentos" ou "60 min".
class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.verdeFundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12, color: AppColors.verdeMuitoEscuro),
      ),
    );
  }
}
