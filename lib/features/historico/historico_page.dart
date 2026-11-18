import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../core/sessao.dart';
import 'package:pi_20262_imt/core/api/api_config.dart';
import 'package:pi_20262_imt/core/models/atendimento.dart';
import '../../core/theme/app_colors.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  late Future<List<Atendimento>> futureAtendimentos;
  
  @override
  void initState() {
    super.initState();
    futureAtendimentos = _carregarAtendimentos();
  }

  Future<List<Atendimento>> _carregarAtendimentos() async {
    try {
      final usuario = Sessao.usuario;

      if (usuario == null) {
        throw Exception('Usuário não autenticado.');
      }

      return await getAtendimentosById(usuario.id);
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _mostrarErro(e.toString());
        });
      }

      rethrow;
    }
  }

Future<void> _mostrarErro(String mensagem) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Erro ao carregar atendimentos'),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fundoConteudo,
      child: Center(
        child: FutureBuilder<List<Atendimento>>(future: futureAtendimentos, builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return const Text(
              'Não foi possível carregar os atendimentos.',
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('Nenhum atendimento encontrado.');
          }

          final atendimentos = snapshot.data!;

          return ListView.builder(
            itemCount: atendimentos.length,
            itemBuilder: (context, index) {
              final atendimento = atendimentos[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            atendimento.cliente,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Text('Início: ${_formatarHorario(atendimento.inicio)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 20),
                          const SizedBox(width: 8),
                          Text('Fim: ${_formatarHorario(atendimento.fim)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.money, size: 20),
                          const SizedBox(width: 8),
                          Text('Valor: ${atendimento.valor != null ? "R\$${atendimento.valor!.toStringAsFixed(2)}" : "Não informado"}'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  String _formatarHorario(DateTime data) {
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  Future<List<Atendimento>> getAtendimentosById(String id) async {
    final baseUrl = ApiConfig.baseUrl;
    
    final resposta = await http.get(
      Uri.parse('$baseUrl/api/atendimentos/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (resposta.statusCode != 200) {
      throw Exception(
        'O servidor retornou o erro ${resposta.statusCode}.',
      );
    }

    final data =
        jsonDecode(resposta.body) as Map<String, dynamic>;

    final atendimentos =
        data['atendimentos'] as List<dynamic>;

    return atendimentos
        .map(
          (a) => Atendimento.fromJson(
            a as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}