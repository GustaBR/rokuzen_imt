import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class MeusSelosPage extends StatelessWidget {
  const MeusSelosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fundoConteudo,
      alignment: Alignment.center,
      child: const Text('Meus selos'),
    );
  }
}
