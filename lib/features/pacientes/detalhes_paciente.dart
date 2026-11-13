import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'paciente_service.dart';

/// Abre uma janela com os dados e a ficha de saúde do paciente.
Future<void> mostrarDetalhesPaciente(BuildContext context, String pacienteId) {
  return showDialog(
    context: context,
    builder: (_) => _DetalhesPaciente(pacienteId: pacienteId),
  );
}

class _DetalhesPaciente extends StatefulWidget {
  final String pacienteId;

  const _DetalhesPaciente({required this.pacienteId});

  @override
  State<_DetalhesPaciente> createState() => _DetalhesPacienteState();
}

class _DetalhesPacienteState extends State<_DetalhesPaciente> {
  late final Future<Paciente> _paciente;

  @override
  void initState() {
    super.initState();
    // Busca uma vez só, quando a janela abre
    _paciente = PacienteService().buscar(widget.pacienteId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.branco,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: FutureBuilder<Paciente>(
          future: _paciente,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              final erro = snapshot.error;
              return _mensagemDeErro(
                erro is PacienteException
                    ? erro.mensagem
                    : 'Não foi possível carregar o paciente.',
              );
            }
            return _conteudo(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _conteudo(Paciente paciente) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  paciente.nome,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (paciente.nascimento != null)
            _informacao(
              Icons.cake_outlined,
              '${_formatarData(paciente.nascimento!)} (${paciente.idade} anos)',
            ),
          if (paciente.celular != null)
            _informacao(Icons.phone_outlined, paciente.celular!),
          if (paciente.profissao != null)
            _informacao(Icons.work_outline, paciente.profissao!),
          const Divider(height: 32),
          const Text(
            'Ficha de saúde',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (paciente.saude.isEmpty)
            const Text(
              'Nada a destacar',
              style: TextStyle(color: AppColors.textoSecundario),
            )
          else
            for (final item in paciente.saude) _itemSaude(item),
          if (paciente.observacoes != null) ...[
            const Divider(height: 32),
            const Text(
              'Observações',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(paciente.observacoes!),
          ],
        ],
      ),
    );
  }

  Widget _informacao(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppColors.textoSecundario),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }

  Widget _itemSaude(ItemSaude item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.alerta ? Icons.warning_amber_rounded : Icons.info_outline,
            size: 18,
            color: item.alerta ? AppColors.aviso : AppColors.textoSecundario,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${item.rotulo}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: item.valor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensagemDeErro(String mensagem) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mensagem, style: const TextStyle(color: AppColors.erro)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

String _formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/${data.year}';
