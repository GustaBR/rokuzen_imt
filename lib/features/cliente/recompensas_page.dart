import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'cliente_service.dart';

class RecompensasPage extends StatefulWidget {
  const RecompensasPage({super.key});

  @override
  State<RecompensasPage> createState() => _RecompensasPageState();
}

class _RecompensasPageState extends State<RecompensasPage> {
  final _service = ClienteService();
  late Future<RecompensasDados> _dados;
  int? _resgatando;

  @override
  void initState() {
    super.initState();
    _dados = _service.buscarRecompensas();
  }

  void _recarregar() {
    setState(() => _dados = _service.buscarRecompensas());
  }

  Future<void> _resgatar(Recompensa recompensa) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resgatar "${recompensa.nome}"?'),
        content: Text('Serão usados ${recompensa.selos} selos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resgatar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    setState(() => _resgatando = recompensa.id);
    try {
      final codigo = await _service.resgatar(recompensa.id);
      if (!mounted) return;
      await _mostrarCodigo(codigo, recompensa.nome);
      _recarregar();
    } on ClienteException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem)),
      );
    } finally {
      if (mounted) setState(() => _resgatando = null);
    }
  }

  Future<void> _mostrarCodigo(String codigo, String nome) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recompensa resgatada! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(nome, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.verdeFundo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                codigo,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mostre este código na recepção para usar sua recompensa.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fundoConteudo,
      child: FutureBuilder<RecompensasDados>(
        future: _dados,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final erro = snapshot.error;
            return Center(
              child: Text(
                erro is ClienteException
                    ? erro.mensagem
                    : 'Não foi possível carregar as recompensas.',
                style: const TextStyle(color: AppColors.erro),
              ),
            );
          }

          final dados = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final largo = constraints.maxWidth >= 600;
              // No celular, um cartão por linha; no computador, lado a lado
              final larguraCartao = largo ? 280.0 : constraints.maxWidth - 32;

              return SingleChildScrollView(
                padding: EdgeInsets.all(largo ? 28 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: AppColors.verde),
                        const SizedBox(width: 8),
                        Text(
                          'Você tem ${dados.saldo} '
                          '${dados.saldo == 1 ? 'selo' : 'selos'}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final recompensa in dados.recompensas)
                          SizedBox(
                            width: larguraCartao,
                            child: _CartaoRecompensa(
                              recompensa: recompensa,
                              saldo: dados.saldo,
                              carregando: _resgatando == recompensa.id,
                              aoResgatar: () => _resgatar(recompensa),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Meus resgates',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (dados.resgates.isEmpty)
                      const Text(
                        'Você ainda não resgatou nenhuma recompensa.',
                        style: TextStyle(color: AppColors.textoSecundario),
                      )
                    else
                      for (final resgate in dados.resgates)
                        _LinhaResgate(resgate: resgate),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CartaoRecompensa extends StatelessWidget {
  final Recompensa recompensa;
  final int saldo;
  final bool carregando;
  final VoidCallback aoResgatar;

  const _CartaoRecompensa({
    required this.recompensa,
    required this.saldo,
    required this.carregando,
    required this.aoResgatar,
  });

  @override
  Widget build(BuildContext context) {
    final disponivel = saldo >= recompensa.selos;
    final faltam = recompensa.selos - saldo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: disponivel ? AppColors.verde : AppColors.borda,
          width: disponivel ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.card_giftcard,
            size: 32,
            color: disponivel ? AppColors.verde : AppColors.cinzaClaro,
          ),
          const SizedBox(height: 12),
          Text(
            recompensa.nome,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (recompensa.descricao != null)
            Text(
              recompensa.descricao!,
              style: const TextStyle(fontSize: 13, color: AppColors.textoSecundario),
            ),
          const SizedBox(height: 12),
          Text(
            '${recompensa.selos} selos',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.verdeEscuro,
            ),
          ),
          const SizedBox(height: 12),
          if (disponivel)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: carregando ? null : aoResgatar,
                child: carregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Resgatar'),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: saldo / recompensa.selos,
                minHeight: 8,
                color: AppColors.verde,
                backgroundColor: AppColors.cinzaMuitoClaro,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: AppColors.textoSecundario),
                const SizedBox(width: 4),
                Text(
                  'Faltam $faltam ${faltam == 1 ? 'selo' : 'selos'}',
                  style: const TextStyle(color: AppColors.textoSecundario),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LinhaResgate extends StatelessWidget {
  final Resgate resgate;

  const _LinhaResgate({required this.resgate});

  @override
  Widget build(BuildContext context) {
    final data = '${resgate.data.day.toString().padLeft(2, '0')}/'
        '${resgate.data.month.toString().padLeft(2, '0')}/${resgate.data.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borda),
      ),
      child: Row(
        children: [
          Icon(
            resgate.usado ? Icons.check_circle : Icons.confirmation_number_outlined,
            color: resgate.usado ? AppColors.cinzaClaro : AppColors.verde,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resgate.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                SelectableText(
                  'Código: ${resgate.codigo} · $data',
                  style: const TextStyle(fontSize: 13, color: AppColors.textoSecundario),
                ),
              ],
            ),
          ),
          Text(
            resgate.usado ? 'Usado' : 'Disponível',
            style: TextStyle(
              color: resgate.usado ? AppColors.textoSecundario : AppColors.verdeEscuro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
