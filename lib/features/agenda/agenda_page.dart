import 'package:flutter/material.dart';
import 'widgets/novo_atendimento.dart';
import '../../core/theme/app_colors.dart';
import 'agenda_service.dart';
import 'datas.dart';
import 'widgets/faixa_semana.dart';
import 'widgets/lista_do_dia.dart';
import 'widgets/proximos_atendimentos.dart';
import 'widgets/grade_horarios.dart';


class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final _service = AgendaService();
  DateTime _diaSelecionado = soData(DateTime.now());
  bool _carregando = false;
  String? _erro;
  AgendaDados? _dados;
  bool _verSemana = false;

  DateTime get _inicioSemana => inicioDaSemana(_diaSelecionado);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Carrega a semana inteira de uma vez (segunda a domingo).
  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await _service.buscar(
        _inicioSemana,
        _inicioSemana.add(const Duration(days: 7)),
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

  /// direcao = -1 volta uma semana, 1 avança uma semana.
  void _mudarSemana(int direcao) {
    setState(() {
      _diaSelecionado = _diaSelecionado.add(Duration(days: 7 * direcao));
    });
    _carregar();
  }

  void _irParaHoje() {
    setState(() => _diaSelecionado = soData(DateTime.now()));
    _carregar();
  }

  /// Trocar de dia dentro da mesma semana não precisa buscar de novo.
  void _selecionarDia(DateTime dia) {
    setState(() {
      _diaSelecionado = dia;
      _verSemana = false;
    });
  }

    /// Abre o formulário; se marcar, vai para o dia e recarrega a agenda.
  Future<void> _novoAtendimento() async {
    final marcado = await mostrarNovoAtendimento(
      context,
      _diaSelecionado,
      _service,
    );
    if (marcado == null) return;

    _mostrarMensagem('Atendimento marcado');
    setState(() => _diaSelecionado = soData(marcado));
    _carregar();
  }

  /// Confirma e remove um atendimento particular.
  Future<void> _removerParticular(Atendimento particular) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover atendimento particular?'),
        content: Text(
          '${particular.cliente}\n'
          '${diaPorExtenso(particular.inicio)}, ${hora(particular.inicio)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await _service.removerParticular(particular.particularId!);
      _mostrarMensagem('Atendimento removido');
      _carregar();
    } on AgendaException catch (e) {
      _mostrarMensagem(e.mensagem);
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fundoConteudo,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largo = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: EdgeInsets.all(largo ? 28 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _titulo(),
                const SizedBox(height: 20),
                // Computador: lado a lado. Celular: um embaixo do outro.
                if (largo)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _painelAgenda()),
                      const SizedBox(width: 20),
                      Expanded(child: ProximosAtendimentos(dados: _dados)),
                    ],
                  )
                else ...[
                  _painelAgenda(),
                  const SizedBox(height: 16),
                  ProximosAtendimentos(dados: _dados),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _titulo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.verdeFundo,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_month_outlined),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agenda completa',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
                      const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _novoAtendimento,
          icon: const Icon(Icons.add),
          label: const Text('Novo atendimento'),
        ),

              const Text(
                'Visualize seus atendimentos da semana',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _painelAgenda() {
    final dados = _dados;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _navegacaoSemana(),
          const SizedBox(height: 16),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_erro != null)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(_erro!, style: const TextStyle(color: AppColors.erro)),
              ),
            )
          else if (dados != null) ...[
                        FaixaSemana(
              inicioSemana: _inicioSemana,
              // Na visão Semana nenhum dia fica destacado
              diaSelecionado: _verSemana ? DateTime(0) : _diaSelecionado,
              dados: dados,
              aoSelecionar: _selecionarDia,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Dia')),
                  ButtonSegment(value: true, label: Text('Semana')),
                ],
                selected: {_verSemana},
                onSelectionChanged: (selecao) {
                  setState(() => _verSemana = selecao.first);
                },
              ),
            ),
            const SizedBox(height: 16),
                        // Semana no computador: grade com os 7 dias lado a lado
            if (_verSemana && MediaQuery.sizeOf(context).width >= 700)
              SizedBox(
                height: 640,
                child: GradeHorarios(
                  dias: [
                    for (var i = 0; i < 7; i++)
                      _inicioSemana.add(Duration(days: i)),
                  ],
                  dados: dados,
                ),
              )
            // Semana no celular: lista agrupada por dia
            else if (_verSemana)
              ..._listaDaSemana(dados)
            else
              ListaDoDia(
                dia: _diaSelecionado,
                dados: dados,
                aoTocarParticular: _removerParticular,
              ),


          ],
        ],
      ),
    );
  }

    /// Todos os dias da semana que têm atendimento, um embaixo do outro.
  List<Widget> _listaDaSemana(AgendaDados dados) {
    final diasComAtendimento = [
      for (var i = 0; i < 7; i++) _inicioSemana.add(Duration(days: i)),
    ].where((dia) => dados.atendimentos.any((a) => mesmoDia(a.inicio, dia))).toList();

    if (diasComAtendimento.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Nenhum atendimento nesta semana',
              style: TextStyle(color: AppColors.textoSecundario),
            ),
          ),
        ),
      ];
    }

    return [
      for (var i = 0; i < diasComAtendimento.length; i++) ...[
        if (i > 0) const Divider(height: 32),
        ListaDoDia(
          dia: diasComAtendimento[i],
          dados: dados,
          aoTocarParticular: _removerParticular,
        ),
      ],
    ];
  }


  Widget _navegacaoSemana() {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: () => _mudarSemana(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  periodoDaSemana(_inicioSemana),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: () => _mudarSemana(1),
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _irParaHoje, child: const Text('Hoje')),
      ],
    );
  }
}
