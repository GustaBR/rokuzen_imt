import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
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
    futureAtendimentos = getAtendimentosById('56a38ca250bd2');
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
            return Text('Erro: ${snapshot.error}');
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
                      const Text(
                        'Atendimento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
}


Future<List<Atendimento>> getAtendimentosById(String id) async {
  final baseUrl = ApiConfig.baseUrl;
  final resposta = await http.get(
    Uri.parse('$baseUrl/api/atendimentos/$id'),
    headers: <String, String> {
      'Content-Type': 'application/json',
    }
  );

  if (resposta.statusCode == 200) {
    final data = jsonDecode(resposta.body) as Map<String, dynamic>;
    final atendimentos = data['atendimentos'] as List<dynamic>;
    
    return List.from(atendimentos.map((a) => Atendimento.fromJson(a as Map<String, dynamic>)));
  } else {
    throw Exception("Falha ao carregar atendimentos");
  }
}