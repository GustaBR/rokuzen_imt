import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../agenda_service.dart';
import '../datas.dart';
import 'campo_hora.dart';

Future<DateTime?> mostrarNovoAtendimento(
  BuildContext context,
  HorarioLivre livre,
  AgendaService service,
) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _NovoAtendimentoDialog(livre: livre, service: service),
  );
}

class _NovoAtendimentoDialog extends StatefulWidget {
  final HorarioLivre livre;
  final AgendaService service;

  const _NovoAtendimentoDialog({required this.livre, required this.service});

  @override
  State<_NovoAtendimentoDialog> createState() => _NovoAtendimentoDialogState();
}

class _NovoAtendimentoDialogState extends State<_NovoAtendimentoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _observacaoController = TextEditingController();
  late TimeOfDay _inicio;
  late TimeOfDay _fim;
  late final List<int> _horas;
  bool _salvando = false;
  String? _erro;

  HorarioLivre get _livre => widget.livre;

  @override
  void initState() {
    super.initState();
    final fimPadrao = _livre.inicio.add(const Duration(hours: 1));
    _inicio = TimeOfDay.fromDateTime(_livre.inicio);
    _fim = TimeOfDay.fromDateTime(
      fimPadrao.isAfter(_livre.fim) ? _livre.fim : fimPadrao,
    );
    _horas = [
      for (var hora = _livre.inicio.hour; hora <= _livre.fim.hour; hora++) hora,
    ];
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  DateTime _comHora(TimeOfDay hora) => DateTime(
        _livre.inicio.year,
        _livre.inicio.month,
        _livre.inicio.day,
        hora.hour,
        hora.minute,
      );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final inicio = _comHora(_inicio);
    final fim = _comHora(_fim);
    if (!fim.isAfter(inicio)) {
      setState(() => _erro = 'O horário final precisa ser depois do inicial');
      return;
    }
    if (!_livre.contem(inicio, fim)) {
      setState(
        () => _erro = 'O atendimento precisa caber no horário livre '
            '(${hora(_livre.inicio)} – ${hora(_livre.fim)})',
      );
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final observacao = _observacaoController.text.trim();
      await widget.service.criarParticular(
        cliente: _clienteController.text.trim(),
        observacao: observacao.isEmpty ? null : observacao,
        inicio: inicio,
        fim: fim,
      );
      if (mounted) Navigator.pop(context, inicio);
    } on AgendaException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo atendimento particular'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.creme,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cinzaClaro),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_outlined, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${diaPorExtenso(_livre.inicio)}\n'
                          'Horário livre: ${hora(_livre.inicio)} – '
                          '${hora(_livre.fim)}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clienteController,
                  maxLength: 100,
                  decoration: decoracaoDeDialogo('Cliente', dica: 'Ex.: João'),
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
                      ? 'Informe o cliente'
                      : null,
                ),
                const SizedBox(height: 8),
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
                TextFormField(
                  controller: _observacaoController,
                  maxLength: 255,
                  decoration: decoracaoDeDialogo(
                    'Observação (opcional)',
                    dica: 'Ex.: domicílio, massagem relaxante',
                  ),
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
}
