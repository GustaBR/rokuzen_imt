
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/sessao.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/login_page.dart';
import 'features/auth/cadastro_page.dart';

import 'features/home/home_page.dart';
import 'features/home/inicio_page.dart';

import 'features/agenda/agenda_page.dart';
import 'features/historico/historico_page.dart';
import 'features/pacientes/cadastrar_paciente_page.dart';
import 'features/perfil/meus_dados_page.dart';

import 'features/cliente/meus_selos_page.dart';
import 'features/cliente/recompensas_page.dart';
import 'features/cliente/meus_dados_cliente_page.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/login',

  redirect: (context, state) {
    final caminho = state.uri.path;
    final publica = caminho == '/login' || caminho == '/cadastro';
    final usuario = Sessao.usuario;

    if (usuario == null) {
      return publica ? null : '/login';
    }

    if (publica) {
      return null;
    }

    final areaCliente = caminho.startsWith('/cliente');

    if (usuario.ehCliente && !areaCliente) {
      return '/cliente/selos';
    }

    if (!usuario.ehCliente && areaCliente) {
      return '/';
    }

    return null;
  },

  routes: [
    // Rotas públicas
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: '/cadastro',
      builder: (context, state) => const CadastroPage(),
    ),

    // Área do cliente
    ShellRoute(
      builder: (context, state, child) => HomePage(
        abas: const [
          'Meus selos',
          'Recompensas',
        ],
        icones: const [
          Icons.stars_outlined,
          Icons.card_giftcard_outlined,
        ],
        caminhos: const [
          '/cliente/selos',
          '/cliente/recompensas',
        ],
        caminhoPerfil: '/cliente/meus-dados',
        child: child,
      ),

      routes: [
        GoRoute(
          path: '/cliente/selos',
          builder: (context, state) => const MeusSelosPage(),
        ),

        GoRoute(
          path: '/cliente/recompensas',
          builder: (context, state) => const RecompensasPage(),
        ),

        GoRoute(
          path: '/cliente/meus-dados',
          builder: (context, state) => const MeusDadosClientePage(),
        ),
      ],
    ),

    // Área do terapeuta
    ShellRoute(
      builder: (context, state, child) {
        return HomePage(
          child: child,
        );
      },

      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const InicioPage(),
              transitionDuration: const Duration(milliseconds: 100),
              reverseTransitionDuration: const Duration(milliseconds: 100),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          },
        ),

        GoRoute(
          path: '/agenda',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const AgendaPage(),
              transitionDuration: const Duration(milliseconds: 100),
              reverseTransitionDuration: const Duration(milliseconds: 100),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          },
        ),

        GoRoute(
          path: '/pacientes/novo',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const CadastrarPacientePage(),
              transitionDuration: const Duration(milliseconds: 100),
              reverseTransitionDuration: const Duration(milliseconds: 100),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          },
        ),

        GoRoute(
          path: '/historico',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const HistoricoPage(),
              transitionDuration: const Duration(milliseconds: 100),
              reverseTransitionDuration: const Duration(milliseconds: 100),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          },
        ),

        GoRoute(
          path: '/meus-dados',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const MeusDadosPage(),
              transitionDuration: const Duration(milliseconds: 100),
              reverseTransitionDuration: const Duration(milliseconds: 100),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          },
        ),
      ],
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Recupera a sessão salva antes de iniciar o aplicativo.
  await Sessao.restaurar();

  runApp(const RokuzenApp());
}

class RokuzenApp extends StatelessWidget {
  const RokuzenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rokuzen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      routerConfig: _router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
