import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../pacientes/detalhes_paciente.dart';
import '../agenda_service.dart';
import '../datas.dart';

class ListaDoDia extends StatelessWidget {
  final DateTime dia;
  final AgendaDados dados;
  final void Function(Atendimento) aoTocarParticular;
  final void Function(HorarioLivre) aoTocarLivre;

  const ListaDoDia({
    super.key,
    required this.dia,
    required this.dados,
    required this.aoTocarParticular,
    required this.aoTocarLivre,
  });

  @override
  Widget build(BuildContext context) {
    final atendimentos =
        dados.atendimentos.where((a) => mesmoDia(a.inicio, dia)).toList();
    final livres = dados.livres.where((l) => mesmoDia(l.inicio, dia)).toList();
    final turnos = dados.turnos.where((t) => mesmoDia(t.inicio, dia)).toList();

    // Tudo numa lista só, por horário. No mesmo horário, o livre (ordem 0)
    // vem antes do particular que está dentro dele (ordem 1).
    final itens = <_Item>[
      for (final livre in livres)
        _Item(
          livre.inicio,
          0,
          AppColors.cinzaClaro,
          _CartaoLivre(livre: livre, aoTocar: aoTocarLivre),
        ),
      for (final atendimento in atendimentos)
        _Item(
          atendimento.inicio,
          1,
          AppColors.verde,
          _CartaoAtendimento(
            atendimento: atendimento,
            aoTocarParticular: aoTocarParticular,
          ),
        ),
    ]..sort((a, b) {
        final porHorario = a.inicio.compareTo(b.inicio);
        return porHorario != 0 ? porHorario : a.ordem.compareTo(b.ordem);
      });

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
        if (itens.isEmpty)
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
          for (var i = 0; i < itens.length; i++)
            _LinhaDoTempo(item: itens[i], ultimo: i == itens.length - 1),
      ],
    );
  }

  String _textoTurno(Turno turno) {
    final fim = turno.fim == null ? '?' : hora(turno.fim!);
    return 'Turno: ${hora(turno.inicio)} – $fim';
  }
}

class _Item {
  final DateTime inicio;
  final int ordem;
  final Color corDoPonto;
  final Widget cartao;

  const _Item(this.inicio, this.ordem, this.corDoPonto, this.cartao);
}

/// Horário à esquerda, bolinha e linha no meio, cartão à direita.
class _LinhaDoTempo extends StatelessWidget {
  final _Item item;
  final bool ultimo;

  const _LinhaDoTempo({required this.item, required this.ultimo});

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight faz a linha do tempo ter a mesma altura do cartão
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                hora(item.inicio),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.corDoPonto,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: item.cartao,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão de atendimento: Rokuzen abre a ficha do paciente,
/// particular oferece remover.
class _CartaoAtendimento extends StatelessWidget {
  final Atendimento atendimento;
  final void Function(Atendimento) aoTocarParticular;

  const _CartaoAtendimento({
    required this.atendimento,
    required this.aoTocarParticular,
  });

  @override
  Widget build(BuildContext context) {
    final duracao = atendimento.fim?.difference(atendimento.inicio).inMinutes;
    final clienteId = atendimento.clienteId;
    final particular = atendimento.ehParticular;

    return Material(
      color: AppColors.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: particular
            ? () => aoTocarParticular(atendimento)
            : clienteId == null
                ? null
                : () => mostrarDetalhesPaciente(context, clienteId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    particular ? AppColors.roxo : AppColors.verdeFundo,
                child: Text(
                  _iniciais(atendimento.cliente),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: particular
                        ? AppColors.branco
                        : AppColors.verdeMuitoEscuro,
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
              if (particular) ...[
                const SizedBox(width: 8),
                const _Etiqueta('Particular'),
              ],
              if (duracao != null) ...[
                const SizedBox(width: 8),
                _Etiqueta('$duracao min'),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textoSecundario),
            ],
          ),
        ),
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

/// Cartão do horário livre: ao tocar, marca particular ou remove.
class _CartaoLivre extends StatelessWidget {
  final HorarioLivre livre;
  final void Function(HorarioLivre) aoTocar;

  const _CartaoLivre({required this.livre, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.creme,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cinzaClaro),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => aoTocar(livre),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.cinzaMuitoClaro,
                child: Icon(
                  Icons.event_available_outlined,
                  size: 18,
                  color: AppColors.cinzaEscuro,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horário livre',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${hora(livre.inicio)} – ${hora(livre.fim)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: AppColors.textoSecundario),
            ],
          ),
        ),
      ),
    );
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
