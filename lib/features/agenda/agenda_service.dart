import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';
import '../../core/sessao.dart';
import '../../core/texto.dart';

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
      cliente: json['cliente'] as String? ?? 'Cliente não informado',
      servico: limparNomeServico(json['servico'] as String? ?? ''),
      clienteId: json['clienteId'] as String?,
    );
  }
}

class Turno {
  final int id;
  final DateTime inicio;
  final DateTime? fim;
  final String? unidade;

  const Turno({
    required this.id,
    required this.inicio,
    required this.fim,
    this.unidade,
  });

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      id: json['id'] as int,
      inicio: DateTime.parse(json['inicio'] as String),
      fim: json['fim'] == null ? null : DateTime.parse(json['fim'] as String),
      unidade: json['unidade'] as String?,
    );
  }

  bool get podeRemover => inicio.isAfter(DateTime.now());
}

class DiaIgnorado {
  final DateTime dia;
  final String motivo;

  const DiaIgnorado({required this.dia, required this.motivo});
}

class ResultadoDisponibilidade {
  final List<DateTime> criados;
  final List<DiaIgnorado> ignorados;

  const ResultadoDisponibilidade({
    required this.criados,
    required this.ignorados,
  });
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
    final dados = await _buscarJson(
      Uri.parse('${ApiConfig.baseUrl}/api/agenda').replace(
        queryParameters: {
          'terapeuta': _idDoTerapeuta(),
          'inicio': _formatarData(inicio),
          'fim': _formatarData(fim),
        },
      ),
    ) as Map<String, dynamic>;

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

  Future<ResultadoDisponibilidade> criarDisponibilidade({
    required String unidade,
    required List<(DateTime, DateTime)> periodos,
  }) async {
    final resposta = await _enviar(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/disponibilidade'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'terapeuta': _idDoTerapeuta(),
          'unidade': unidade,
          'periodos': [
            for (final (inicio, fim) in periodos)
              {
                'inicio': inicio.toIso8601String(),
                'fim': fim.toIso8601String(),
              },
          ],
        }),
      ),
    );
    if (resposta.statusCode != 201) {
      throw AgendaException(_mensagemDeErro(resposta));
    }

    final dados =
        jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    return ResultadoDisponibilidade(
      criados: [
        for (final item in dados['criados'] as List)
          DateTime.parse(item as String),
      ],
      ignorados: [
        for (final item
            in (dados['ignorados'] as List).cast<Map<String, dynamic>>())
          DiaIgnorado(
            dia: DateTime.parse(item['inicio'] as String),
            motivo: item['motivo'] as String,
          ),
      ],
    );
  }

  Future<void> removerDisponibilidade(int id) async {
    final resposta = await _enviar(
      () => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/disponibilidade/$id').replace(
          queryParameters: {'terapeuta': _idDoTerapeuta()},
        ),
      ),
    );
    if (resposta.statusCode != 200) {
      throw AgendaException(_mensagemDeErro(resposta));
    }
  }

  String _idDoTerapeuta() {
    final usuario = Sessao.usuario;
    if (usuario == null) {
      throw const AgendaException('Sessão expirada. Faça login novamente.');
    }
    return usuario.id;
  }

  Future<Object?> _buscarJson(Uri endereco) async {
    final resposta = await _enviar(() => http.get(endereco));
    if (resposta.statusCode != 200) {
      throw AgendaException(_mensagemDeErro(resposta));
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }

  Future<http.Response> _enviar(
    Future<http.Response> Function() chamada,
  ) async {
    try {
      return await chamada().timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const AgendaException('Não foi possível conectar ao servidor.');
    }
  }

  String _mensagemDeErro(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes))
          as Map<String, dynamic>;
      return dados['erro'] as String? ??
          'Não foi possível concluir a operação.';
    } catch (_) {
      return 'Não foi possível concluir a operação.';
    }
  }

  String _formatarData(DateTime data) =>
      '${data.year}-${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}