import 'package:flutter/material.dart';
import '../../shared/widgets/base_layout.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      itensMenu: [
        ItemMenu(titulo: 'Opção 1', aoClicar: () {}),
        ItemMenu(titulo: 'Opção 2', aoClicar: () {}),
        ItemMenu(titulo: 'Opção 3', aoClicar: () {}),
      ],
      corpo: const Center(
        child: Text('Conteúdo da tela aqui'),
      ),
    );
  }
}
