
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int abaSelecionada = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoConteudo,
      body: SafeArea(
        child: Column(
          children: [
            _cabecalho(),
            _menuAbas(),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.verdeFundo,
        border: Border(
          bottom: BorderSide(color: AppColors.borda),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 190,
            height: 62,
            fit: BoxFit.contain,
            alignment: Alignment.center
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
                  setState(() {
                    abaSelecionada = index;
                  });
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

  Widget _conteudo() {
    return const SizedBox.expand();
  }
}
