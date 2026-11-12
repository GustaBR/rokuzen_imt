import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../agenda_service.dart';
import '../datas.dart';

enum _Tipo { rokuzen, particular }

/// Abre o formulário de novo atendimento.
/// Devolve o horário marcado, ou null se a pessoa cancelar.
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
  _Tipo _tipo = _Tipo.rokuzen;
  late DateTime _dia;
  TimeOfDay _inicio = const TimeOfDay(hour: 10, minute: 0);
  bool _salvando = false;
  String? _erro;

  // Campos do atendimento Rokuzen
  PacienteResumo? _paciente;
  List<Servico> _servicos = [];
  Servico? _servico;
  List<String> _duracoes = [];
  String? _duracao;

  // Campos do atendimento particular
  final _clienteController = TextEditingController();
  final _observacaoController = TextEditingController();
  TimeOfDay _fim = const TimeOfDay(hour: 11, minute: 0);

  /// Horas (06 a 23) e minutos (de 15 em 15) dos campos de horário.
  static final _horas = [for (var hora = 6; hora <= 23; hora++) hora];
  static const _minutos = [0, 15, 30, 45];

  @override
  void initState() {
    super.initState();
    // Não deixa começar num dia que já passou
    final hoje = soData(DateTime.now());
    _dia = widget.diaInicial.isBefore(hoje) ? hoje : widget.diaInicial;
    _carregarServicos();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarServicos() async {
    try {
      final servicos = await widget.service.buscarServicos();
      if (mounted) setState(() => _servicos = servicos);
    } on AgendaException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    }
  }

  /// Ao trocar o serviço, limpa a duração e busca as durações dele.
  Future<void> _escolherServico(Servico? servico) async {
    setState(() {
      _servico = servico;
      _duracoes = [];
      _duracao = null;
    });
    if (servico == null) return;
    try {
      final duracoes = await widget.service.buscarDuracoes(servico.id);
      if (mounted) setState(() => _duracoes = duracoes);
    } on AgendaException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    }
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

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      if (_tipo == _Tipo.rokuzen) {
        await widget.service.criarAtendimentoRokuzen(
          pacienteId: _paciente!.id,
          servicoId: _servico!.id,
          duracao: _duracao!,
          inicio: inicio,
        );
      } else {
        final fim = _comHora(_fim);
        if (!fim.isAfter(inicio)) {
          throw const AgendaException(
            'O horário final precisa ser depois do inicial',
          );
        }
        final observacao = _observacaoController.text.trim();
        await widget.service.criarParticular(
          cliente: _clienteController.text.trim(),
          observacao: observacao.isEmpty ? null : observacao,
          inicio: inicio,
          fim: fim,
        );
      }
      if (mounted) Navigator.pop(context, inicio);
    } on AgendaException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rokuzen = _tipo == _Tipo.rokuzen;

    return AlertDialog(
      title: const Text('Novo atendimento'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<_Tipo>(
                  segments: const [
                    ButtonSegment(value: _Tipo.rokuzen, label: Text('Rokuzen')),
                    ButtonSegment(
                      value: _Tipo.particular,
                      label: Text('Particular'),
                    ),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (selecao) => setState(() {
                    _tipo = selecao.first;
                    _erro = null;
                  }),
                ),
                const SizedBox(height: 20),
                if (rokuzen) ..._camposRokuzen() else ..._camposParticular(),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _escolherDia,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(diaPorExtenso(_dia)),
                ),
                const SizedBox(height: 8),

                _campoHora('Início', _inicio, (h) => _inicio = h),
                // No Rokuzen o fim é calculado pela duração
                if (!rokuzen) ...[
                  const SizedBox(height: 8),
                  _campoHora('Fim', _fim, (h) => _fim = h),
                ],

                if (!rokuzen) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _observacaoController,
                    maxLength: 255,
                    decoration: _decoracao(
                      'Observação (opcional)',
                      dica: 'Ex.: domicílio, massagem relaxante',
                    ),
                  ),
                ],
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

  List<Widget> _camposRokuzen() {
    return [
      // Busca do paciente: sugere enquanto a pessoa digita
      Autocomplete<PacienteResumo>(
        displayStringForOption: (paciente) => paciente.nome,
        optionsBuilder: (valor) async {
          final termo = valor.text.trim();
          if (termo.length < 3) return const <PacienteResumo>[];
          try {
            return await widget.service.buscarPacientes(termo);
          } on AgendaException {
            return const <PacienteResumo>[];
          }
        },
        onSelected: (paciente) => _paciente = paciente,
        fieldViewBuilder: (context, controller, focusNode, aoEnviar) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: _decoracao(
              'Paciente',
              dica: 'Digite ao menos 3 letras do nome',
              icone: const Icon(Icons.search),
            ),
            // Se a pessoa mudar o texto, precisa escolher da lista de novo
            onChanged: (_) => _paciente = null,
            validator: (_) =>
                _paciente == null ? 'Escolha um paciente da lista' : null,
          );
        },
        optionsViewBuilder: (context, aoEscolher, opcoes) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 260,
                  maxWidth: 440,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final paciente in opcoes)
                      ListTile(
                        title: Text(paciente.nome),
                        // Nascimento e celular para diferenciar homônimos
                        subtitle: Text(
                          [
                            if (paciente.nascimento != null)
                              'Nasc. ${paciente.nascimento}',
                            if (paciente.celular != null) paciente.celular!,
                          ].join(' · '),
                        ),
                        onTap: () => aoEscolher(paciente),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 4),
      const Text(
        'Não encontrou? Cadastre o paciente antes em "Cadastrar Paciente".',
        style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<Servico>(
        initialValue: _servico,
        isExpanded: true,
        decoration: _decoracao('Serviço'),
        items: [
          for (final servico in _servicos)
            DropdownMenuItem(
              value: servico,
              child: Text(servico.nome, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _escolherServico,
        validator: (valor) => valor == null ? 'Escolha o serviço' : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        // A key muda junto com o serviço, para a duração voltar a ficar vazia
        key: ValueKey(_servico?.id),
        initialValue: _duracao,
        decoration: _decoracao('Duração'),
        items: [
          for (final duracao in _duracoes)
            DropdownMenuItem(value: duracao, child: Text(duracao)),
        ],
        onChanged: (duracao) => setState(() => _duracao = duracao),
        validator: (valor) => valor == null ? 'Escolha a duração' : null,
      ),
    ];
  }

  List<Widget> _camposParticular() {
    return [
      TextFormField(
        controller: _clienteController,
        maxLength: 100,
        decoration: _decoracao('Cliente', dica: 'Ex.: João'),
        validator: (valor) => (valor == null || valor.trim().isEmpty)
            ? 'Informe o cliente'
            : null,
      ),
    ];
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
              setState(
                () => aoMudar(TimeOfDay(hour: hora, minute: valor.minute)),
              );
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
              setState(
                () => aoMudar(TimeOfDay(hour: valor.hour, minute: minuto)),
              );
            },
          ),
        ),
      ],
    );
  }

  /// O tema deixa os campos brancos e sem borda; dentro da janela
  /// (que também é branca) eles precisam de borda para aparecer.
  InputDecoration _decoracao(String rotulo, {String? dica, Widget? icone}) {
    return InputDecoration(
      labelText: rotulo,
      hintText: dica,
      prefixIcon: icone,
      filled: true,
      fillColor: AppColors.creme,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cinzaClaro),
      ),
    );
  }
}
