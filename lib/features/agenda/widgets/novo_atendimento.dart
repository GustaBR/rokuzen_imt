import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../agenda_service.dart';
import '../datas.dart';

Future<DateTime?> mostrarNovoAtendimento(
  BuildContext context,
  DateTime diaInicial,
  AgendaService service,
) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) =>
        _NovoAtendimentoDialog(diaInicial: diaInicial, service: service),
  );
}

class _NovoAtendimentoDialog extends StatefulWidget {
  final DateTime diaInicial;
  final AgendaService service;

  const _NovoAtendimentoDialog({
    required this.diaInicial,
    required this.service,
  });

  @override
  State<_NovoAtendimentoDialog> createState() => _NovoAtendimentoDialogState();
}

class _NovoAtendimentoDialogState extends State<_NovoAtendimentoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _observacaoController = TextEditingController();
  late DateTime _dia;
  TimeOfDay _inicio = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _fim = const TimeOfDay(hour: 19, minute: 0);
  bool _salvando = false;
  String? _erro;

  /// Horas (06 a 23) e minutos (de 15 em 15) dos campos de horário.
  static final _horas = [for (var hora = 6; hora <= 23; hora++) hora];
  static const _minutos = [0, 15, 30, 45];

  @override
  void initState() {
    super.initState();
    // Não deixa começar num dia que já passou
    final hoje = soData(DateTime.now());
    _dia = widget.diaInicial.isBefore(hoje) ? hoje : widget.diaInicial;
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _escolherDia() async {
    final hoje = soData(DateTime.now());
    final dia = await showDatePicker(
      context: context,
      initialDate: _dia,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365)),
    );
    if (dia != null) setState(() => _dia = dia);
  }

  DateTime _comHora(TimeOfDay hora) =>
      DateTime(_dia.year, _dia.month, _dia.day, hora.hour, hora.minute);

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final inicio = _comHora(_inicio);
    final fim = _comHora(_fim);
    if (!fim.isAfter(inicio)) {
      setState(() => _erro = 'O horário final precisa ser depois do inicial');
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
                const Text(
                  'Os atendimentos da Rokuzen são marcados pela secretaria.',
                  style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clienteController,
                  maxLength: 100,
                  decoration: _decoracao('Cliente', dica: 'Ex.: João'),
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
                      ? 'Informe o cliente'
                      : null,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _escolherDia,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(diaPorExtenso(_dia)),
                ),
                const SizedBox(height: 12),
                _campoHora('Início', _inicio, (h) => _inicio = h),
                const SizedBox(height: 8),
                _campoHora('Fim', _fim, (h) => _fim = h),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacaoController,
                  maxLength: 255,
                  decoration: _decoracao(
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

  /// Horário em dois campos curtos: hora e minuto.
  Widget _campoHora(
    String rotulo,
    TimeOfDay valor,
    void Function(TimeOfDay) aoMudar,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            rotulo,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: valor.hour,
            decoration: _decoracao('hora'),
            menuMaxHeight: 300,
            items: [
              for (final hora in _horas)
                DropdownMenuItem(
                  value: hora,
                  child: Text(hora.toString().padLeft(2, '0')),
                ),
            ],
            onChanged: (hora) {
              if (hora == null) return;
              setState(() => aoMudar(TimeOfDay(hour: hora, minute: valor.minute)));
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: TextStyle(fontSize: 20)),
        ),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: valor.minute,
            decoration: _decoracao('min'),
            items: [
              for (final minuto in _minutos)
                DropdownMenuItem(
                  value: minuto,
                  child: Text(minuto.toString().padLeft(2, '0')),
                ),
            ],
            onChanged: (minuto) {
              if (minuto == null) return;
              setState(() => aoMudar(TimeOfDay(hour: valor.hour, minute: minuto)));
            },
          ),
        ),
      ],
    );
  }

  /// O tema deixa os campos brancos e sem borda; dentro da janela
  /// (que também é branca) eles precisam de borda para aparecer.
  InputDecoration _decoracao(String rotulo, {String? dica}) {
    return InputDecoration(
      labelText: rotulo,
      hintText: dica,
      filled: true,
      fillColor: AppColors.creme,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cinzaClaro),
      ),
    );
  }
}
