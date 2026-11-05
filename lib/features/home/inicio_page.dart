
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

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

  Widget _cartaoAgendaHoje(BuildContext context, bool mobile) {
    return _cartaoCabecalho(
      mobile: mobile,
      icone: Icons.calendar_month_outlined,
      titulo: 'Agenda de hoje',
      textoBotao: 'Ver agenda completa',
      aoClicar: () => context.go('/agenda'),
    );
  }

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
}
