import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../agenda_service.dart';
import '../datas.dart';
import 'campo_hora.dart';

/// Abre o formulário para sinalizar horários livres em um ou vários dias.
/// Devolve o resultado, ou null se a pessoa cancelar.
Future<ResultadoHorariosLivres?> mostrarNovoHorarioLivre(
  BuildContext context,
  DateTime diaInicial,
  AgendaService service,
) {
  return showDialog<ResultadoHorariosLivres>(
    context: context,
    builder: (_) =>
        _NovoHorarioLivreDialog(diaInicial: diaInicial, service: service),
  );
}

class _NovoHorarioLivreDialog extends StatefulWidget {
  final DateTime diaInicial;
  final AgendaService service;

  const _NovoHorarioLivreDialog({
    required this.diaInicial,
    required this.service,
  });

  @override
  State<_NovoHorarioLivreDialog> createState() =>
      _NovoHorarioLivreDialogState();
}

class _NovoHorarioLivreDialogState extends State<_NovoHorarioLivreDialog> {
  late DateTime _de;
  late DateTime _ate;

  /// Dias da semana escolhidos (1 = segunda ... 7 = domingo).
  final Set<int> _diasDaSemana = {1, 2, 3, 4, 5, 6, 7};

  TimeOfDay _inicio = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _fim = const TimeOfDay(hour: 20, minute: 0);
  bool _salvando = false;
  String? _erro;

  /// Horas de 06 a 23.
  static final _horas = [for (var hora = 6; hora <= 23; hora++) hora];

  /// Maior período que dá para marcar de uma vez (o servidor aceita até 62).
  static const _maximoDeDias = 62;

  bool get _variosDias => _ate.isAfter(_de);

  @override
  void initState() {
    super.initState();
    // Não deixa começar num dia que já passou
    final hoje = soData(DateTime.now());
    _de = widget.diaInicial.isBefore(hoje) ? hoje : widget.diaInicial;
    _ate = _de;
  }

  /// [dias] dias depois de [data] (sem problema com horário de verão).
  DateTime _somarDias(DateTime data, int dias) =>
      DateTime(data.year, data.month, data.day + dias);

  Future<void> _escolherDe() async {
    final hoje = soData(DateTime.now());
    final dia = await showDatePicker(
      context: context,
      initialDate: _de,
      firstDate: hoje,
      lastDate: _somarDias(hoje, 365),
    );
    if (dia == null) return;
    setState(() {
      _de = dia;
      // "Até" não pode ficar antes do "De" nem passar do limite
      if (_ate.isBefore(_de) ||
          _ate.isAfter(_somarDias(_de, _maximoDeDias - 1))) {
        _ate = _de;
      }
    });
  }

  Future<void> _escolherAte() async {
    final dia = await showDatePicker(
      context: context,
      initialDate: _ate,
      firstDate: _de,
      lastDate: _somarDias(_de, _maximoDeDias - 1),
    );
    if (dia != null) setState(() => _ate = dia);
  }

  /// Um período (início, fim) para cada dia escolhido.
  List<(DateTime, DateTime)> _periodos() {
    final periodos = <(DateTime, DateTime)>[];
    for (var dia = _de; !dia.isAfter(_ate); dia = _somarDias(dia, 1)) {
      // Com um dia só, os dias da semana não importam
      if (_variosDias && !_diasDaSemana.contains(dia.weekday)) continue;
      periodos.add((_comHora(dia, _inicio), _comHora(dia, _fim)));
    }
    return periodos;
  }

  DateTime _comHora(DateTime dia, TimeOfDay hora) =>
      DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);

  Future<void> _salvar() async {
    final minutosInicio = _inicio.hour * 60 + _inicio.minute;
    final minutosFim = _fim.hour * 60 + _fim.minute;
    if (minutosFim <= minutosInicio) {
      setState(() => _erro = 'O horário final precisa ser depois do inicial');
      return;
    }

    final periodos = _periodos();
    if (periodos.isEmpty) {
      setState(
        () => _erro = 'Nenhum dos dias da semana escolhidos está no período',
      );
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final resultado = await widget.service.criarHorariosLivres(periodos);
      if (mounted) Navigator.pop(context, resultado);
    } on AgendaException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantidade = _periodos().length;

    return AlertDialog(
      title: const Text('Novo horário livre'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sinalize quando você está disponível fora da escala. '
                'Para vários dias, escolha o período e os dias da semana.',
                style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _botaoData('De', _de, _escolherDe)),
                  const SizedBox(width: 8),
                  Expanded(child: _botaoData('Até', _ate, _escolherAte)),
                ],
              ),
              if (_variosDias) ...[
                const SizedBox(height: 12),
                const Text(
                  'Dias da semana',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var dia = 1; dia <= 7; dia++)
                      FilterChip(
                        label: Text(diasDaSemanaCurtos[dia - 1]),
                        selected: _diasDaSemana.contains(dia),
                        onSelected: (marcado) => setState(() {
                          if (marcado) {
                            _diasDaSemana.add(dia);
                          } else {
                            _diasDaSemana.remove(dia);
                          }
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              CampoHora(
                rotulo: 'Início',
                valor: _inicio,
                horas: _horas,
                aoMudar: (hora) => setState(() => _inicio = hora),
              ),
              const SizedBox(height: 8),
              CampoHora(
                rotulo: 'Fim',
                valor: _fim,
                horas: _horas,
                aoMudar: (hora) => setState(() => _fim = hora),
              ),
              const SizedBox(height: 12),
              Text(
                quantidade == 1
                    ? 'Será marcado 1 dia'
                    : 'Serão marcados $quantidade dias',
                style: const TextStyle(color: AppColors.textoSecundario),
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _erro!,
                    style: const TextStyle(color: AppColors.erro),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _botaoData(String rotulo, DateTime data, VoidCallback aoTocar) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return OutlinedButton.icon(
      onPressed: aoTocar,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text('$rotulo: $dia/$mes/${data.year}'),
    );
  }
}
