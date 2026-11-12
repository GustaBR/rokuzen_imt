import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';


class HomePage extends StatefulWidget {
  final Widget child;

  const HomePage({
    super.key,
    required this.child,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

void _selecionarAba(int index) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  context.go(caminhos[index]);
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

  final List<String> caminhos = const [
  '/',
  '/agenda',
  '/pacientes/novo',
  '/historico',
];


  bool get _mobile =>
      MediaQuery.of(context).size.width < 600;

    void _confirmarSaida() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.branco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.verdeFundo,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.marrom,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Deseja realmente sair?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.marrom,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Você será redirecionado para a tela de login.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.cinza,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.marrom,
                side: const BorderSide(color: AppColors.borda),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Não'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verde,
                foregroundColor: AppColors.branco,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );
  }

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
                onPressed: () => Scaffold.of(context).openDrawer(),
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
            child: _botaoPerfil(),
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
          _botaoPerfil(),
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
            final selecionada =
              GoRouterState.of(context).uri.path == caminhos[index];

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
              final selecionada =
                GoRouterState.of(context).uri.path == caminhos[index];

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
                  _selecionarAba(index);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    return widget.child;
  }


  Widget _botaoPerfil() {
    return PopupMenuButton<String>(
      tooltip: 'Perfil',
      icon: const Icon(
        Icons.person_outline,
        color: AppColors.cinza,
        size: 28,
      ),
      color: AppColors.branco,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 45),
      onSelected: (opcao) {
        if (opcao == 'meus_dados') {
          context.go('/meus-dados');
        } else if (opcao == 'sair') {
          _confirmarSaida();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'meus_dados',
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppColors.marrom,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Meus Dados',
                style: TextStyle(color: AppColors.marrom),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'sair',
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: AppColors.erro,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Sair',
                style: TextStyle(color: AppColors.erro),
              ),
            ],
          ),
        ),
      ],
    );
  }

}