import 'package:flutter/material.dart';

import '../../../core/models/usuario.dart';
import '../../../core/sessao.dart';
import '../../../core/theme/app_colors.dart';
import '../agenda_service.dart';
import '../datas.dart';
import 'campo_hora.dart';

Future<ResultadoDisponibilidade?> mostrarNovaDisponibilidade(
  BuildContext context,
  DateTime diaInicial,
  AgendaService service,
) {
  return showDialog<ResultadoDisponibilidade>(
    context: context,
    builder: (_) =>
        _NovaDisponibilidadeDialog(diaInicial: diaInicial, service: service),
  );
}

class _NovaDisponibilidadeDialog extends StatefulWidget {
  final DateTime diaInicial;
  final AgendaService service;

  const _NovaDisponibilidadeDialog({
    required this.diaInicial,
    required this.service,
  });

  @override
  State<_NovaDisponibilidadeDialog> createState() =>
      _NovaDisponibilidadeDialogState();
}

class _NovaDisponibilidadeDialogState
    extends State<_NovaDisponibilidadeDialog> {
  late final List<Unidade> _unidades;
  String? _unidadeId;
  late DateTime _de;
  late DateTime _ate;
  final Set<int> _diasDaSemana = {1, 2, 3, 4, 5};
  final Set<DateTime> _diasRetirados = {};
  TimeOfDay _inicio = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _fim = const TimeOfDay(hour: 18, minute: 0);
  bool _salvando = false;
  String? _erro;

  static final _horas = [for (var hora = 6; hora <= 23; hora++) hora];
  static const _maximoDeDias = 62;

  bool get _variosDias => _ate.isAfter(_de);

  @override
  void initState() {
    super.initState();
    _unidades = Sessao.usuario?.unidades ?? [];
    _unidadeId = Sessao.unidade?.id ??
        (_unidades.isEmpty ? null : _unidades.first.id);

    final hoje = soData(DateTime.now());
    _de = widget.diaInicial.isBefore(hoje) ? hoje : widget.diaInicial;
    _ate = _de;
  }

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

  List<DateTime> _diasDoPeriodo() {
    return [
      for (var dia = _de; !dia.isAfter(_ate); dia = _somarDias(dia, 1))
        if (!_variosDias || _diasDaSemana.contains(dia.weekday)) dia,
    ];
  }

  List<(DateTime, DateTime)> _periodos() {
    return [
      for (final dia in _diasDoPeriodo())
        if (!_diasRetirados.contains(dia))
          (_comHora(dia, _inicio), _comHora(dia, _fim)),
    ];
  }

  DateTime _comHora(DateTime dia, TimeOfDay hora) =>
      DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);

  Future<void> _salvar() async {
    final unidade = _unidadeId;
    if (unidade == null) {
      setState(
        () => _erro = 'Não encontramos uma unidade no seu cadastro. '
            'Fale com a secretaria.',
      );
      return;
    }

    final minutosInicio = _inicio.hour * 60 + _inicio.minute;
    final minutosFim = _fim.hour * 60 + _fim.minute;
    if (minutosFim <= minutosInicio) {
      setState(() => _erro = 'O horário final precisa ser depois do inicial');
      return;
    }

    final periodos = _periodos();
    if (periodos.isEmpty) {
      setState(() => _erro = 'Nenhum dia escolhido no período');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final resultado = await widget.service.criarDisponibilidade(
        unidade: unidade,
        periodos: periodos,
      );
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
      title: const Text('Horários disponíveis'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informe quando você pode atender. A secretaria vai marcar '
                'seus atendimentos dentro desses horários.',
                style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 16),
              if (_unidades.length > 1) ...[
                DropdownButtonFormField<String>(
                  initialValue: _unidadeId,
                  isExpanded: true,
                  decoration: decoracaoDeDialogo('Unidade'),
                  items: [
                    for (final unidade in _unidades)
                      DropdownMenuItem(
                        value: unidade.id,
                        child: Text(unidade.nome),
                      ),
                  ],
                  onChanged: (id) => setState(() => _unidadeId = id),
                ),
                const SizedBox(height: 12),
              ] else if (_unidades.length == 1) ...[
                Text(
                  'Unidade: ${_unidades.first.nome}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
              ],
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
              if (_variosDias) ...[
                const SizedBox(height: 16),
                const Text('Dias', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text(
                  'Toque num dia para tirá-lo (ex.: uma folga).',
                  style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final dia in _diasDoPeriodo())
                      FilterChip(
                        label: Text(_diaCurto(dia)),
                        selected: !_diasRetirados.contains(dia),
                        onSelected: (marcado) => setState(() {
                          if (marcado) {
                            _diasRetirados.remove(dia);
                          } else {
                            _diasRetirados.add(dia);
                          }
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                quantidade == 1
                    ? 'Será adicionado 1 dia à sua escala'
                    : 'Serão adicionados $quantidade dias à sua escala',
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

  String _diaCurto(DateTime dia) =>
      '${diasDaSemanaCurtos[dia.weekday - 1]} '
      '${dia.day.toString().padLeft(2, '0')}/'
      '${dia.month.toString().padLeft(2, '0')}';

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