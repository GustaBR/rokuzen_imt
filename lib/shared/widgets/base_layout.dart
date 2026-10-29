import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Um botão do menu lateral.
class ItemMenu {
  final String titulo;
  final VoidCallback aoClicar;

  const ItemMenu({required this.titulo, required this.aoClicar});
}

/// Layout padrão de todas as telas internas do app.
/// Desktop: barra superior + menu lateral fixo.
/// Mobile: AppBar + menu sanduíche (Drawer).
class BaseLayout extends StatelessWidget {
  final Widget corpo;
  final List<ItemMenu> itensMenu;
  final VoidCallback? aoClicarPerfil;

  static const double larguraDesktop = 800;
  static const double larguraMenu = 215;

  const BaseLayout({
    super.key,
    required this.corpo,
    this.itensMenu = const [],
    this.aoClicarPerfil,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= larguraDesktop) {
          return _desktop();
        }
        return _mobile();
      },
    );
  }

  Widget _desktop() {
    return Scaffold(
      body: Column(
        children: [
          // Barra superior
          Container(
            height: 70,
            decoration: const BoxDecoration(
              color: AppColors.verdeFundo,
              border: Border(bottom: BorderSide(color: AppColors.borda)),
            ),
            child: Row(
              children: [
                Container(
                  width: larguraMenu,
                  alignment: Alignment.center,
                  decoration: itensMenu.isEmpty
                  ? null
                  : const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.borda)),
                  ),
                  child: const _Logo(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: aoClicarPerfil,
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          // Menu lateral + conteúdo
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (itensMenu.isNotEmpty)
                Container(
                  width: larguraMenu,
                  decoration: const BoxDecoration(
                    color: AppColors.verdeFundo,
                    border: Border(right: BorderSide(color: AppColors.borda)),
                  ),
                  child: _ListaMenu(itens: itensMenu),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: corpo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobile() {
    return Scaffold(
      appBar: AppBar(
        title: const _Logo(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: aoClicarPerfil,
          ),
        ],
      ),
      drawer: itensMenu.isEmpty
          ? null
          : Drawer(
              child: SafeArea(
                child: _ListaMenu(itens: itensMenu, fecharAoClicar: true),
              ),
            ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: corpo,
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/logo.png', height: 44);
  }
}


class _ListaMenu extends StatelessWidget {
  final List<ItemMenu> itens;
  final bool fecharAoClicar;

  const _ListaMenu({required this.itens, this.fecharAoClicar = false});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: itens.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, i) {
        final item = itens[i];
        return SizedBox(
          height: 40,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.branco,
              foregroundColor: AppColors.marromEscuro,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () {
              if (fecharAoClicar) Navigator.of(context).pop();
              item.aoClicar();
            },
            child: Text(item.titulo),
          ),
        );
      },
    );
  }
}
