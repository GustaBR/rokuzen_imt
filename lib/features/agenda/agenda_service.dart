import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../core/texto.dart';

import '../../core/api/api_config.dart';
import '../../core/sessao.dart';

class Atendimento {
  final DateTime inicio;
  final DateTime? fim;
  final String cliente;
  final String servico;
  final String? clienteId;

  
  final int? particularId;

  const Atendimento({
    required this.inicio,
    required this.fim,
    required this.cliente,
    required this.servico,
    required this.clienteId,
    this.particularId,
  });

  bool get ehParticular => particularId != null;

  factory Atendimento.fromJson(Map<String, dynamic> json) {
    return Atendimento(
      inicio: DateTime.parse(json['inicio'] as String),
      fim: json['fim'] == null ? null : DateTime.parse(json['fim'] as String),
      cliente: json['cliente'] as String? ?? 'Cliente não informado',
      servico: limparNomeServico(json['servico'] as String? ?? ''),
      clienteId: json['clienteId'] as String?,
    );
  }

  factory Atendimento.particularFromJson(Map<String, dynamic> json) {
    return Atendimento(
      inicio: DateTime.parse(json['inicio'] as String),
      fim: DateTime.parse(json['fim'] as String),
      cliente: json['cliente'] as String? ?? 'Atendimento particular',
      servico: json['observacao'] as String? ?? 'Atendimento particular',
      clienteId: null,
      particularId: json['id'] as int,
    );
  }
}

/// Um turno de trabalho na escala (tabela events).
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


class HorarioLivre {
  final int id;
  final DateTime inicio;
  final DateTime fim;

  const HorarioLivre({
    required this.id,
    required this.inicio,
    required this.fim,
  });

  factory HorarioLivre.fromJson(Map<String, dynamic> json) {
    return HorarioLivre(
      id: json['id'] as int,
      inicio: DateTime.parse(json['inicio'] as String),
      fim: DateTime.parse(json['fim'] as String),
    );
  }

  bool contem(DateTime de, DateTime ate) =>
      !de.isBefore(inicio) && !ate.isAfter(fim);
}


class DiaIgnorado {
  final DateTime dia;
  final String motivo;

  const DiaIgnorado({required this.dia, required this.motivo});
}

class ResultadoHorariosLivres {
  final List<DateTime> criados;
  final List<DiaIgnorado> ignorados;

  const ResultadoHorariosLivres({
    required this.criados,
    required this.ignorados,
  });
}





class AgendaDados {
  final List<Atendimento> atendimentos;
  final List<Turno> turnos;
  final List<HorarioLivre> livres;

  const AgendaDados({
    required this.atendimentos,
    required this.turnos,
    required this.livres,
  });
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

    
    final atendimentos = [
      for (final item in dados['sessoes'] as List)
        Atendimento.fromJson(item as Map<String, dynamic>),
      for (final item in dados['particulares'] as List)
        Atendimento.particularFromJson(item as Map<String, dynamic>),
    ]..sort((a, b) => a.inicio.compareTo(b.inicio));

      return AgendaDados(
      atendimentos: atendimentos,
      turnos: [
        for (final item in dados['escala'] as List)
          Turno.fromJson(item as Map<String, dynamic>),
      ],
      livres: [
        for (final item in dados['livres'] as List)
          HorarioLivre.fromJson(item as Map<String, dynamic>),
      ],
    );

  }







  /// Registra um atendimento particular do terapeuta logado.
  Future<void> criarParticular({
    required String cliente,
    required String? observacao,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final resposta = await _enviar(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/particulares'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'terapeuta': _idDoTerapeuta(),
          'cliente': cliente,
          'observacao': observacao,
          'inicio': inicio.toIso8601String(),
          'fim': fim.toIso8601String(),
        }),
      ),
    );
    if (resposta.statusCode != 201) {
      throw AgendaException(_mensagemDeErro(resposta));
    }
  }

  Future<void> removerParticular(int id) async {
    final resposta = await _enviar(
      () => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/particulares/$id').replace(
          queryParameters: {'terapeuta': _idDoTerapeuta()},
        ),
      ),
    );
    if (resposta.statusCode != 200) {
      throw AgendaException(_mensagemDeErro(resposta));
    }
  }

      /// Sinaliza horários livres do terapeuta logado, um período por dia.
  Future<ResultadoHorariosLivres> criarHorariosLivres(
    List<(DateTime, DateTime)> periodos,
  ) async {
    final resposta = await _enviar(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/horarios_livres'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'terapeuta': _idDoTerapeuta(),
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
    return ResultadoHorariosLivres(
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


  
  Future<void> removerHorarioLivre(int id) async {
    final resposta = await _enviar(
      () => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/horarios_livres/$id').replace(
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

  /// GET que devolve o JSON da resposta (ou lança AgendaException).
  Future<Object?> _buscarJson(Uri endereco) async {
    final resposta = await _enviar(() => http.get(endereco));
    if (resposta.statusCode != 200) {
      throw AgendaException(_mensagemDeErro(resposta));
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }

  /// Faz a chamada com tempo limite e transforma falha de rede em mensagem.
  Future<http.Response> _enviar(
    Future<http.Response> Function() chamada,
  ) async {
    try {
      return await chamada().timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const AgendaException('Não foi possível conectar ao servidor.');
    }
  }

  /// Usa a mensagem de erro que o servidor mandou, se houver.
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



