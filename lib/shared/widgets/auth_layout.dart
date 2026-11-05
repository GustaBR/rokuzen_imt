import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// layout das telas de autenticação
// desktop: formulário a esquerda + logo a direita
// mobile: logo em cima + formulário embaixo.

class AuthLayout extends StatelessWidget {
  final Widget formulario;

  static const double larguraDesktop = 800;
  static const double larguraFormulario = 420;

  const AuthLayout({super.key, required this.formulario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= larguraDesktop) {
            return _desktop(context);
          }
          return _mobile(context);
        },
      ),
    );
  }

  Widget _desktop(BuildContext context) {
    return Container(
      color: AppColors.verdeFundo,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lado do formulário
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: larguraFormulario + 112),
                  child: Container(
                    padding: const EdgeInsets.all(56),
                    decoration: BoxDecoration(
                      color: AppColors.branco,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.preto.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: formulario,
                  ),
                ),
              ),
            ),
          ),
          // Lado do logo
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', width: 460),
                  const SizedBox(height: 24),
                  Text(
                    'Massagem Terapêutica',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      letterSpacing: 2,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


        Widget _mobile(BuildContext context) {
    // Espaços ocupados pelo sistema do celular (barra de status e barra de navegação)
    final espacoTopo = MediaQuery.paddingOf(context).top;
    final espacoBaixo = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: AppColors.verdeFundo,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 48 + espacoTopo, 16, 24 + espacoBaixo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Image.asset('assets/images/logo.png', height: 70),
            const SizedBox(height: 40),
            // Bloco verde com o formulário
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.circular(24),
              ),
              child: formulario,
            ),
          ],
        ),
      ),
    );
  }
}