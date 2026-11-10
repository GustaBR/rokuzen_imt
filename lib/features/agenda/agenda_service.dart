import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';
import '../../core/sessao.dart';


class Atendimento {
  final DateTime inicio;
  final DateTime? fim;
  final String cliente;
  final String servico;
  final String? clienteId;

  const Atendimento({
    required this.inicio,
    required this.fim,
    required this.cliente,
    required this.servico,
    required this.clienteId,
  });

  factory Atendimento.fromJson(Map<String, dynamic> json) {
    return Atendimento(
      inicio: DateTime.parse(json['inicio'] as String),
      fim: json['fim'] == null ? null : DateTime.parse(json['fim'] as String),
      cliente: json['cliente'] as String? ?? 'Cliente não inforamado',
      servico: _limparNomeServico(json['servico'] as String? ?? ''),
      clienteId: json['clienteId'] as String?,
    );
  }
}

class Turno {
  final DateTime inicio;
  final DateTime? fim;

  const Turno({required this.inicio, required this.fim});

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      inicio: DateTime.parse(json['inicio'] as String),
      fim: json['fim'] == null ? null : DateTime.parse(json['fim'] as String),
    );
  }
}

class AgendaDados {
  final List<Atendimento> atendimentos;
  final List<Turno> turnos;

  const AgendaDados({required this.atendimentos, required this.turnos});
}

class AgendaException implements Exception {
  final String mensagem;

  const AgendaException(this.mensagem);
}

class AgendaService {
  Future<AgendaDados> buscar(DateTime inicio, DateTime fim) async {
    final usuario = Sessao.usuario;
    if (usuario == null) {
      throw const AgendaException('Sessão expirada. Faça login novamente.');
    }

    final endereco = Uri.parse('${ApiConfig.baseUrl}/api/agenda').replace(
      queryParameters: {
        'terapeuta': usuario.id,
        'inicio': _formatarData(inicio),
        'fim': _formatarData(fim),
      },
    );

    final http.Response resposta;
    try {
      resposta = await http.get(endereco).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const AgendaException('Não foi possível conectar ao servidor.');
    }

    if (resposta.statusCode != 200) {
      throw const AgendaException('Erro ao carregar a agenda.');
    }

    final dados =
        jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;

    return AgendaDados(
      atendimentos: [
        for (final item in dados['sessoes'] as List)
          Atendimento.fromJson(item as Map<String, dynamic>),
      ],
      turnos: [
        for (final item in dados['escala'] as List)
          Turno.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  String _formatarData(DateTime data) =>
      '${data.year}-${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}

/// Os nomes dos serviços no banco têm um prefixo usado para ordenar as listas
/// (ex.: "1.Quick Massage", "D.GIFT CARD", "(2020)3.MACA"). Aqui ele é removido.
String _limparNomeServico(String nome) =>
    nome.replaceFirst(RegExp(r'^(\(\d+\))?\s*\w{1,2}\.\s*'), '');
