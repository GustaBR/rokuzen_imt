
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import "../agenda/agenda_page.dart";

class HomePage extends StatefulWidget {  
  final int abaInicial;

  const HomePage({
    super.key,
    this.abaInicial = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int abaSelecionada;

  @override
  void initState() {
    super.initState();
    abaSelecionada = widget.abaInicial;
  }
  


void _abrirAgenda() {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return const HomePage(abaInicial: 1);
      },
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}



void _selecionarAba(int index) {
    setState(() {
      abaSelecionada = index;
    });
  }
  

  final List<String> abas = const [
    'Início',
    'Agenda',
    'Cadastrar Paciente',
    'Histórico de consultas',
  ];

  final List<IconData> icones = const [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.people_outline,
    Icons.assignment_outlined,
  ];

  bool get _mobile =>
      MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.fundoConteudo,
        drawer: _mobile ? _menuLateral() : null,
        body: SafeArea(
          child: Column(
            children: [
              _cabecalho(),
              if (!_mobile) _menuAbas(),
              Expanded(
                child: _conteudo(),
              ),
            ],
          ),
        ),
      );
  }

  Widget _cabecalho() {
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(
        horizontal: _mobile ? 12 : 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.verdeFundo,
        border: Border(
          bottom: BorderSide(color: AppColors.borda),
        ),
      ),
      child: _mobile
    ? Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (context) => IconButton(
                tooltip: 'Abrir menu',
                onPressed: () =>
                    Scaffold.of(context).openDrawer(),
                icon: const Icon(
                  Icons.menu,
                  color: AppColors.marrom,
                  size: 28,
                ),
              ),
            ),
          ),
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 155,
              height: 62,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Perfil',
              onPressed: () {},
              icon: const Icon(
                Icons.person_outline,
                color: AppColors.cinza,
                size: 28,
              ),
            ),
          ),
        ],
      )
    : Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 190,
            height: 62,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Perfil',
            onPressed: () {},
            icon: const Icon(
              Icons.person_outline,
              color: AppColors.cinza,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuAbas() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.fundoConteudo,
        border: Border(
          bottom: BorderSide(color: AppColors.borda),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 10,
        ),
        child: Row(
          children: List.generate(abas.length, (index) {
            final selecionada = abaSelecionada == index;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  _selecionarAba(index);
                },
                icon: Icon(
                  icones[index],
                  size: 19,
                ),
                label: Text(abas[index]),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.marrom,
                  backgroundColor: selecionada
                      ? AppColors.verdeFundo
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
// Menu lateral do Mobile

  Widget _menuLateral() {
    return Drawer(
      backgroundColor: AppColors.fundoConteudo,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 110,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.verdeFundo,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/logo.png',
                width: 180,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 12),

            ...List.generate(abas.length, (index) {
              final selecionada = abaSelecionada == index;

              return ListTile(
                leading: Icon(
                  icones[index],
                  color: AppColors.marrom,
                ),
                title: Text(
                  abas[index],
                  style: const TextStyle(
                    color: AppColors.marrom,
                  ),
                ),
                selected: selecionada,
                selectedTileColor: AppColors.verdeFundo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                onTap: () {
                  Navigator.of(context).pop();

                  if (index == 1) {
                    _abrirAgenda();
                  } else {
                    _selecionarAba(index);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
// Função para abrir e fechar a aba agenda

Widget _cartaoAgendaHoje(bool mobile) {
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

// Botão para abrir a aba agenda
        TextButton.icon(
          onPressed: _abrirAgenda,
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
  );
}

  Widget _conteudo() {
  switch (abaSelecionada) {
    case 0:
      return _telaInicial();

    case 1:
      return const AgendaPage();

    case 2:
      return const SizedBox.expand();

    case 3:
      return const SizedBox.expand();

    default:
      return const SizedBox.expand();
  }
}

  Widget _telaInicial() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 700;

      return SingleChildScrollView(
        padding: EdgeInsets.all(mobile ? 16 : 28),
        child: _cartaoAgendaHoje(mobile),
      );
    },
  );
}
}

