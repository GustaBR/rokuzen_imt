import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Cartão branco com título e linha divisória,
/// usado como área principal de conteúdo das telas.
class PainelConteudo extends StatelessWidget {
  final String titulo;
  final Widget filho;

  const PainelConteudo({
    super.key,
    required this.titulo,
    required this.filho,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Text(
              titulo,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: filho,
            ),
          ),
        ],
      ),
    );
  }
}
