import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'agenda_service.dart';

enum _Visao { dia, semana }

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final _service = AgendaService();
  _Visao _visao = _Visao.dia;
  DateTime _data = _soData(DateTime.now());
  bool _carregando = false;
  String? _erro;
  AgendaDados? _dados;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Visão Dia: o próprio dia. Visão Semana: a segunda-feira da semana.
  DateTime get _inicio => _visao == _Visao.dia
      ? _data
      : _data.subtract(Duration(days: _data.weekday - 1));

  int get _quantidadeDias => _visao == _Visao.dia ? 1 : 7;

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await _service.buscar(
        _inicio,
        _inicio.add(Duration(days: _quantidadeDias)),
      );
      if (!mounted) return;
      setState(() => _dados = dados);
    } on AgendaException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// direcao = -1 volta, 1 avança (um dia ou uma semana).
  void _mudarPeriodo(int direcao) {
    setState(() {
      _data = _data.add(Duration(days: _quantidadeDias * direcao));
    });
    _carregar();
  }

  void _irParaHoje() {
    setState(() => _data = _soData(DateTime.now()));
    _carregar();
  }

  void _mudarVisao(_Visao visao) {
    setState(() => _visao = visao);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fundoConteudo,
      child: Column(
        children: [
          _cabecalho(),
          Expanded(child: _conteudo()),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _mudarPeriodo(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _tituloPeriodo(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => _mudarPeriodo(1),
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(onPressed: _irParaHoje, child: const Text('Hoje')),
            ],
          ),
          SegmentedButton<_Visao>(
            segments: const [
              ButtonSegment(value: _Visao.dia, label: Text('Dia')),
              ButtonSegment(value: _Visao.semana, label: Text('Semana')),
            ],
            selected: {_visao},
            onSelectionChanged: (selecao) => _mudarVisao(selecao.first),
          ),
        ],
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Text(_erro!, style: const TextStyle(color: AppColors.erro)),
      );
    }

    final dados = _dados;
    if (dados == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < _quantidadeDias; i++)
          _secaoDoDia(_inicio.add(Duration(days: i)), dados),
      ],
    );
  }

  Widget _secaoDoDia(DateTime dia, AgendaDados dados) {
    final atendimentos =
        dados.atendimentos.where((a) => _mesmoDia(a.inicio, dia)).toList();
    final turnos = dados.turnos.where((t) => _mesmoDia(t.inicio, dia)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Na visão semanal, cada dia ganha um título
        if (_visao == _Visao.semana)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              _formatarDia(dia),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            turnos.isEmpty
                ? 'Sem escala neste dia'
                : turnos.map(_textoTurno).join('  ·  '),
            style: const TextStyle(color: AppColors.textoSecundario),
          ),
        ),
        if (atendimentos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Nenhuma sessão marcada'),
          )
        else
          for (final atendimento in atendimentos) _cartao(atendimento),
      ],
    );
  }

  Widget _cartao(Atendimento atendimento) {
    final horario = atendimento.fim == null
        ? _hora(atendimento.inicio)
        : '${_hora(atendimento.inicio)} – ${_hora(atendimento.fim!)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSessao,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${atendimento.cliente} - ${atendimento.servico}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(horario),
        ],
      ),
    );
  }

  String _tituloPeriodo() {
    if (_visao == _Visao.dia) return _formatarDia(_data);
    final ultimo = _inicio.add(const Duration(days: 6));
    return '${_inicio.day}/${_inicio.month} – ${ultimo.day}/${ultimo.month}';
  }

  String _textoTurno(Turno turno) {
    final fim = turno.fim == null ? '?' : _hora(turno.fim!);
    return 'Turno: ${_hora(turno.inicio)} – $fim';
  }
}

// ----- Funções de data -----

const _diasDaSemana = [
  'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo',
];

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

DateTime _soData(DateTime data) => DateTime(data.year, data.month, data.day);

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatarDia(DateTime data) =>
    '${_diasDaSemana[data.weekday - 1]}, ${data.day} de ${_meses[data.month - 1]}';

String _hora(DateTime data) =>
    '${data.hour.toString().padLeft(2, '0')}:'
    '${data.minute.toString().padLeft(2, '0')}';
