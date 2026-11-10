import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_config.dart';

class ItemSaude {
  final String rotulo;
  final String valor;
  final bool alerta;

  const ItemSaude({
  required this.rotulo,
  required this.valor,
  required this.alerta,
  });

  factory ItemSaude.fromJson(Map<String, dynamic> json) {
    return ItemSaude(
      rotulo: json['rotulo'] as String,
      valor: json['valor'] as String,
      alerta: json['alerta'] as bool,
    );
  }
}

class Paciente {
  final String nome;
  final DateTime? nascimento;
  final String? celular;
  final String? profissao;
  final String? observacoes;
  final List<ItemSaude> saude;

  const Paciente({
    required this.nome,
    required this.nascimento,
    required this.celular,
    required this.profissao,
    required this.observacoes,
    required this.saude,
  });

  int? get idade {
    final nascimento = this.nascimento;
    if (nascimento == null) return null;
    final hoje = DateTime.now();
    var anos = hoje.year - nascimento.year;

    if (hoje.month < nascimento.month ||
          (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
            anos--;
          }
    return anos;
  }

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      nome: json['nome'] as String? ?? 'Sem nome',
      nascimento: DateTime.tryParse(json['nascimento'] as String? ?? ''),
      celular: json['celular'] as String?,
      profissao: json['profissao'] as String?,
      observacoes: json['observacoes'] as String?,
      saude: [
        for (final item in json['saude'] as List)
          ItemSaude.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

class PacienteException implements Exception {
  final String mensagem;

  const PacienteException(this.mensagem);
}

class PacienteService {
  Future<Paciente> buscar(String id) async {
    final http.Response resposta;
    try {
      resposta = await http
          .get(Uri.parse(
            '${ApiConfig.baseUrl}/api/pacientes/${Uri.encodeComponent(id)}'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const PacienteException('Não foi possível conectar ao servidor');
    }

    if (resposta.statusCode == 404) {
      throw const PacienteException('Paciente não encontrado.');
    }

    if (resposta.statusCode != 200) {
      throw const PacienteException('Erro ao carregar o paciente.');
    }

    return Paciente.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
