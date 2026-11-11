import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../agenda_service.dart';

/// Grade de horários da agenda: uma coluna por dia, com o turno da escala
/// ao fundo e as sessões como blocos do tamanho da duração.
/// Com 1 dia vira a visão Dia; com 7 dias, a visão Semana.
class GradeHorarios extends StatelessWidget {
  final List<DateTime> dias;
  final AgendaDados dados;

  const GradeHorarios({super.key, required this.dias, required this.dados});

  /// Altura, em pixels, de uma hora na grade.
  static const double _alturaHora = 80;
  static const double _larguraColunaHoras = 56;

  @override
  Widget build(BuildContext context) {
    final (horaInicial, horaFinal) = _faixaDeHoras();
    final totalHoras = horaFinal - horaInicial;

    return Column(
      children: [
        if (dias.length > 1) _cabecalhoDias(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: SizedBox(
              height: totalHoras * _alturaHora,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _colunaHoras(horaInicial, totalHoras),
                  for (final dia in dias)
                    Expanded(child: _colunaDia(dia, horaInicial, totalHoras)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Nomes dos dias no topo (só na visão Semana).
  Widget _cabecalhoDias() {
    final hoje = DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: _larguraColunaHoras),
          for (final dia in dias)
            Expanded(
              child: Text(
                '${_diasCurtos[dia.weekday - 1]} ${dia.day}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _mesmoDia(dia, hoje)
                      ? AppColors.verdeEscuro
                      : AppColors.textoPrincipal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Coluna da esquerda com as horas (08:00, 09:00...).
  Widget _colunaHoras(int horaInicial, int totalHoras) {
    return SizedBox(
      width: _larguraColunaHoras,
      child: Column(
        children: [
          for (var i = 0; i < totalHoras; i++)
            SizedBox(
              height: _alturaHora,
              child: Text(
                '${(horaInicial + i).toString().padLeft(2, '0')}:00',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Coluna de um dia: turno ao fundo, linhas das horas, sessões e "agora".
  Widget _colunaDia(DateTime dia, int horaInicial, int totalHoras) {
    final turnos = dados.turnos.where((t) => _mesmoDia(t.inicio, dia));
    final atendimentos =
        dados.atendimentos.where((a) => _mesmoDia(a.inicio, dia));
    final agora = DateTime.now();
    final fimDaGrade = totalHoras * _alturaHora;

    // Converte um horário na posição vertical (em pixels) dentro da grade
    double posicao(DateTime horario) =>
        ((horario.hour - horaInicial) * 60 + horario.minute) *
        _alturaHora /
        60;

    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.borda)),
      ),
      child: Stack(
        children: [
          // Turno da escala, como fundo
          for (final turno in turnos)
            Positioned(
              top: posicao(turno.inicio),
              height: max(
                (turno.fim == null ? fimDaGrade : posicao(turno.fim!)) -
                    posicao(turno.inicio),
                0,
              ),
              left: 0,
              right: 0,
              child: const ColoredBox(color: AppColors.verdeFundo),
            ),
          // Linha de cada hora
          for (var i = 1; i < totalHoras; i++)
            Positioned(
              top: i * _alturaHora,
              left: 0,
              right: 0,
              child: const Divider(height: 1),
            ),
          // Sessões
          for (final atendimento in atendimentos)
            Positioned(
              top: posicao(atendimento.inicio),
              height: max(
                posicao(atendimento.fim ??
                        atendimento.inicio.add(const Duration(hours: 1))) -
                    posicao(atendimento.inicio),
                28,
              ),
              left: 4,
              right: 4,
              child: _BlocoAtendimento(
                atendimento: atendimento,
                compacto: dias.length > 1,
              ),
            ),
          // Linha da hora atual
          if (_mesmoDia(dia, agora) &&
              agora.hour >= horaInicial &&
              agora.hour < horaInicial + totalHoras)
            Positioned(
              top: posicao(agora),
              left: 0,
              right: 0,
              child: Container(height: 2, color: AppColors.destaque),
            ),
        ],
      ),
    );
  }

  /// Horas exibidas: das 8h às 20h, ampliando se algum turno
  /// ou sessão começar antes ou terminar depois.
  (int, int) _faixaDeHoras() {
    var inicio = 8;
    var fim = 20;
    final horarios = <DateTime>[
      for (final turno in dados.turnos) ...[
        turno.inicio,
        if (turno.fim != null) turno.fim!,
      ],
      for (final atendimento in dados.atendimentos) ...[
        atendimento.inicio,
        if (atendimento.fim != null) atendimento.fim!,
      ],
    ];
    for (final horario in horarios) {
      inicio = min(inicio, horario.hour);
      final horaCheia = horario.minute > 0 ? horario.hour + 1 : horario.hour;
      fim = max(fim, horaCheia);
    }
    return (inicio, min(fim, 24));
  }
}

class _BlocoAtendimento extends StatelessWidget {
  final Atendimento atendimento;
  final bool compacto;

  const _BlocoAtendimento({required this.atendimento, required this.compacto});

  @override
  Widget build(BuildContext context) {
    final horario = atendimento.fim == null
        ? _hora(atendimento.inicio)
        : '${_hora(atendimento.inicio)} – ${_hora(atendimento.fim!)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: atendimento.ehParticular
              ? AppColors.verdeFundo
              : AppColors.cardSessao,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 4,
              child: ColoredBox(
                color: atendimento.ehParticular
                    ? AppColors.roxo
                    : AppColors.verde,
              ),
            ),
            Expanded(
              // Em sessões curtas o texto é cortado, em vez de
              // aparecer o aviso de "overflow" do Flutter
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        atendimento.cliente,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compacto ? 12 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        compacto
                            ? horario
                            : '${atendimento.servico} · $horario',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: compacto ? 11 : 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----- Funções de data -----

const _diasCurtos = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _hora(DateTime data) =>
    '${data.hour.toString().padLeft(2, '0')}:'
    '${data.minute.toString().padLeft(2, '0')}';
