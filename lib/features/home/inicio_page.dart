import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../agenda/agenda_service.dart';
import '../agenda/datas.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage>
    with WidgetsBindingObserver {
  final AgendaService _agendaService = AgendaService();

  Timer? _timerAtualizacaoDia;

  late DateTime _hoje;
  AgendaDados? _dados;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _hoje = soData(DateTime.now());
    _carregarAgenda();

    // Verifica a mudança de dia a cada minuto.
    _timerAtualizacaoDia = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _verificarMudancaDeDia(),
    );
  }

  // Verifica se a data atual mudou.
  void _verificarMudancaDeDia() {
    final hojeAtual = soData(DateTime.now());

    final mudouDeDia = hojeAtual.year != _hoje.year ||
        hojeAtual.month != _hoje.month ||
        hojeAtual.day != _hoje.day;

    if (mudouDeDia) {
      setState(() {
        _hoje = hojeAtual;
        _dados = null;
      });

      // Busca os atendimentos da nova semana.
      _carregarAgenda();
    }
  }

  // Verifica a data quando o aplicativo volta ao primeiro plano.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verificarMudancaDeDia();
    }
  }

  // Busca os dados da agenda no backend.
  Future<void> _carregarAgenda() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final inicioSemana = inicioDaSemana(_hoje);

      final dados = await _agendaService.buscar(
        inicioSemana,
        inicioSemana.add(const Duration(days: 7)),
      );

      if (!mounted) return;

      setState(() {
        _dados = dados;
      });
    } on AgendaException catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar a agenda.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // Retorna somente os atendimentos do dia atual.
  List<Atendimento> get _atendimentosDeHoje {
    if (_dados == null) return [];

    return _dados!.atendimentos
        .where((atendimento) => mesmoDia(atendimento.inicio, _hoje))
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  // Formata a data atual.
  String get _dataFormatada {
    const dias = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];

    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    return '${dias[_hoje.weekday - 1]}, '
        '${_hoje.day} de ${meses[_hoje.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(mobile ? 16 : 28),
          child: mobile
              ? Column(
                  children: [
                    _cartaoAgendaHoje(context, true),
                    const SizedBox(height: 16),
                    _cartaoPacientesRecentes(context, true),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _cartaoAgendaHoje(context, false),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _cartaoPacientesRecentes(context, false),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // Cartão da agenda de hoje.
  Widget _cartaoAgendaHoje(BuildContext context, bool mobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.marrom,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Agenda de hoje',
                    style: TextStyle(
                      color: AppColors.marrom,
                      fontSize: mobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.go('/agenda'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver agenda completa'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.marrom,
                  backgroundColor: AppColors.verdeFundo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _dataFormatada,
            style: const TextStyle(
              color: AppColors.cinza,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.borda),
          const SizedBox(height: 8),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_erro != null)
            _estadoVazio(
              _erro!,
              icone: Icons.error_outline,
            )
          else if (_atendimentosDeHoje.isEmpty)
            _estadoVazio(
              'Nenhum atendimento agendado para hoje.',
              icone: Icons.event_available_outlined,
            )
          else
            ...List.generate(
              _atendimentosDeHoje.length,
              (index) => _itemAtendimento(
                _atendimentosDeHoje[index],
                index == _atendimentosDeHoje.length - 1,
              ),
            ),
        ],
      ),
    );
  }

  // Item individual de atendimento.
  Widget _itemAtendimento(Atendimento atendimento, bool ultimo) {
    final duracao =
        atendimento.fim?.difference(atendimento.inicio).inMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              hora(atendimento.inicio),
              style: const TextStyle(
                color: AppColors.marrom,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.verde,
              borderRadius: BorderRadius.circular(4),
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
                  style: const TextStyle(
                    color: AppColors.marrom,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  atendimento.servico,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.cinza,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (duracao != null) ...[
            const SizedBox(width: 8),
            Text(
              '$duracao min',
              style: const TextStyle(
                color: AppColors.cinza,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Estados de carregamento, erro e agenda vazia.
  Widget _estadoVazio(
    String mensagem, {
    required IconData icone,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            icone,
            color: AppColors.cinza,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.cinza,
              fontSize: 13,
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _carregarAgenda,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }

  // Cartão de pacientes recentes.
  Widget _cartaoPacientesRecentes(
    BuildContext context,
    bool mobile,
  ) {
    return _cartaoCabecalho(
      mobile: mobile,
      icone: Icons.people_outline,
      titulo: 'Pacientes recentes',
      textoBotao: 'Ver todos',
      aoClicar: () => context.go('/historico'),
    );
  }

  // Cabeçalho reutilizável dos cartões.
  Widget _cartaoCabecalho({
    required bool mobile,
    required IconData icone,
    required String titulo,
    required String textoBotao,
    required VoidCallback aoClicar,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borda),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icone,
                color: AppColors.marrom,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  color: AppColors.marrom,
                  fontSize: mobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: aoClicar,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(textoBotao),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.marrom,
              backgroundColor: AppColors.verdeFundo,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timerAtualizacaoDia?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}